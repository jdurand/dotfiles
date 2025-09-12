use anyhow::Result;
use async_trait::async_trait;

use crate::core::{session::{SessionContext, SessionItem, SessionMetadata}, tmux::TmuxClient};
use crate::plugins::SessionPlugin;

pub struct RecentPlugin {
    tmux: TmuxClient,
}

impl RecentPlugin {
    pub fn new() -> Self {
        Self {
            tmux: TmuxClient::new(),
        }
    }
}

#[async_trait]
impl SessionPlugin for RecentPlugin {
    fn name(&self) -> &str {
        "recent"
    }

    fn description(&self) -> &str {
        "Most recent active session"
    }

    fn priority(&self) -> u32 {
        0  // Highest priority - shows first
    }

    fn dependencies(&self) -> Vec<&str> {
        vec!["tmux"]
    }

    async fn discover(&self, context: &SessionContext) -> Result<Vec<SessionItem>> {
        let mut sessions = Vec::new();

        // Find the most recent non-current session
        if let Some(most_recent) = context.active_sessions.first() {
            // Skip if it's the current session (active plugin will handle it)
            if let Some(current) = &context.current_session {
                if most_recent == current {
                    return Ok(sessions);
                }
            }

            let metadata = SessionMetadata::new("recent".to_string())
                .with_exists(true);

            let session_item = SessionItem::new(
                most_recent.clone(),
                "recent".to_string(),
                self.priority(),
                metadata,
            );

            sessions.push(session_item);
        }

        Ok(sessions)
    }

    async fn resolve(&self, session_name: &str, _context: &SessionContext) -> Result<SessionMetadata> {
        if self.tmux.has_session(session_name).await {
            let session_path = self.tmux.get_session_path(session_name).await?;

            let mut metadata = SessionMetadata::new("recent".to_string())
                .with_exists(true);

            if let Some(path) = session_path {
                metadata = metadata.with_path(path);
            }

            Ok(metadata)
        } else {
            Ok(SessionMetadata::new("recent".to_string()).with_exists(false))
        }
    }

    async fn can_handle(&self, session_name: &str, context: &SessionContext) -> bool {
        // The recent plugin only handles the most recent non-current session
        if let Some(most_recent) = context.active_sessions.first() {
            session_name == most_recent
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
            "\x1b[1;33m★ {}\x1b[0m (\x1b[1;33m{} windows\x1b[0m) \x1b[0;90m[most recent]\x1b[0m\n",
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
            "\x1b[1;33m★\x1b[0m - Most recent session".to_string(),
        ]
    }
}
