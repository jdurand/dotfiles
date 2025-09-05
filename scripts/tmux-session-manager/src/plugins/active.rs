use anyhow::Result;
use async_trait::async_trait;

use crate::core::{session::{SessionContext, SessionItem, SessionMetadata}, tmux::TmuxClient};
use crate::plugins::SessionPlugin;

pub struct ActivePlugin {
    tmux: TmuxClient,
}

impl ActivePlugin {
    pub fn new() -> Self {
        Self {
            tmux: TmuxClient::new(),
        }
    }
}

#[async_trait]
impl SessionPlugin for ActivePlugin {
    fn name(&self) -> &str {
        "active"
    }

    fn description(&self) -> &str {
        "Currently active tmux sessions"
    }

    fn priority(&self) -> u32 {
        10
    }

    fn dependencies(&self) -> Vec<&str> {
        vec!["tmux"]
    }

    async fn discover(&self, context: &SessionContext) -> Result<Vec<SessionItem>> {
        let mut sessions = Vec::new();

        // Add all active sessions except current and scratch
        for session_name in &context.active_sessions {
            if let Some(current) = &context.current_session {
                if session_name == current {
                    continue; // Skip current session, we'll add it at the end
                }
            }

            let metadata = SessionMetadata::new("active".to_string())
                .with_exists(true);

            let session_item = SessionItem::new(
                session_name.clone(),
                "active".to_string(),
                self.priority(),
                metadata,
            );

            sessions.push(session_item);
        }

        // Add current session at the end if it exists and is not scratch
        if let Some(current) = &context.current_session {
            if !current.contains("scratch") {
                let metadata = SessionMetadata::new("active".to_string())
                    .with_exists(true);

                let session_item = SessionItem::new(
                    current.clone(),
                    "active".to_string(),
                    self.priority(),
                    metadata,
                ).with_current(true);

                sessions.push(session_item);
            }
        }

        Ok(sessions)
    }

    async fn resolve(&self, session_name: &str, _context: &SessionContext) -> Result<SessionMetadata> {
        if self.tmux.has_session(session_name).await {
            let session_path = self.tmux.get_session_path(session_name).await?;

            let mut metadata = SessionMetadata::new("active".to_string())
                .with_exists(true);

            if let Some(path) = session_path {
                metadata = metadata.with_path(path.clone());

                // Check if session is in a worktree
                let git_file = std::path::Path::new(&path).join(".git");
                if git_file.exists() {
                    if let Ok(contents) = tokio::fs::read_to_string(&git_file).await {
                        if contents.contains("gitdir:") {
                            metadata = metadata.with_property("in_worktree".to_string(), "true".to_string());
                        } else {
                            metadata = metadata.with_property("in_worktree".to_string(), "false".to_string());
                        }
                    }
                } else {
                    metadata = metadata.with_property("in_worktree".to_string(), "false".to_string());
                }
            }

            Ok(metadata)
        } else {
            Ok(SessionMetadata::new("active".to_string()).with_exists(false))
        }
    }

    async fn can_handle(&self, session_name: &str, context: &SessionContext) -> bool {
        // The active plugin only handles sessions that are in the active_sessions list
        // and current session (but not worktree sessions, which should be handled by worktree plugin)

        // Check if it's in active sessions
        let is_active = context.active_sessions.contains(&session_name.to_string());

        // Check if it's current session
        let is_current = context.current_session.as_ref() == Some(&session_name.to_string());

        if is_active || is_current {
            // Additional check: if it's a worktree session, let the worktree plugin handle it
            // We can do a quick check by seeing if the session path has a .git file (worktree indicator)
            if self.tmux.has_session(session_name).await {
                if let Ok(Some(path)) = self.tmux.get_session_path(session_name).await {
                    let git_file = std::path::Path::new(&path).join(".git");
                    if git_file.is_file() {
                        // This is a worktree, let the worktree plugin handle it
                        return false;
                    }
                }
            }
            true
        } else {
            false
        }
    }

    async fn switch(&self, session_name: &str, _metadata: &SessionMetadata) -> Result<()> {
        if TmuxClient::is_inside_tmux() {
            self.tmux.switch_client(session_name).await
        } else {
            self.tmux.attach_session(session_name).await
        }
    }

    async fn preview(&self, session_name: &str, metadata: &SessionMetadata) -> Result<String> {
        if !metadata.exists {
            return Ok(format!(
                "\x1b[0;31mSession '{}' is not active\x1b[0m\n\nThis session will be created when selected.",
                session_name
            ));
        }

        // Get session info
        let (windows, _attached) = self.tmux.get_session_info(session_name).await?;

        let mut preview = format!(
            "\x1b[1;32m● {}\x1b[0m (\x1b[1;33m{} windows\x1b[0m)\n",
            session_name, windows
        );
        preview.push_str("\x1b[0;90m────────────────────────────────────────\x1b[0m\n");

        // Try to capture pane content
        match self.tmux.capture_pane(session_name).await {
            Ok(content) => preview.push_str(&content),
            Err(_) => {
                preview.push_str("\x1b[0;31mCould not capture session content\x1b[0m\n");
                preview.push_str("Session may be busy or inaccessible");
            }
        }

        Ok(preview)
    }

    fn get_help_text(&self) -> Vec<String> {
        vec![
            "\x1b[1;32m●\x1b[0m - Active session (green)".to_string(),
            "\x1b[1;32m→\x1b[0m - Current session".to_string(),
        ]
    }
}