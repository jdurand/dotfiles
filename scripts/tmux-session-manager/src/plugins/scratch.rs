use anyhow::Result;
use async_trait::async_trait;

use crate::core::{session::{SessionContext, SessionItem, SessionMetadata}, tmux::TmuxClient};
use crate::plugins::SessionPlugin;

pub struct ScratchPlugin {
    tmux: TmuxClient,
}

impl ScratchPlugin {
    pub fn new() -> Self {
        Self {
            tmux: TmuxClient::new(),
        }
    }
}

#[async_trait]
impl SessionPlugin for ScratchPlugin {
    fn name(&self) -> &str {
        "scratch"
    }

    fn description(&self) -> &str {
        "Scratch/temporary sessions"
    }

    fn priority(&self) -> u32 {
        999 // Lowest priority - always appears last
    }

    fn dependencies(&self) -> Vec<&str> {
        vec!["tmux"]
    }

    async fn discover(&self, context: &SessionContext) -> Result<Vec<SessionItem>> {
        let mut sessions = Vec::new();

        for session_name in &context.scratch_sessions {
            let is_current = context.current_session.as_ref() == Some(session_name);

            let metadata = SessionMetadata::new("scratch".to_string())
                .with_exists(true);

            // Find the timestamp for this session from all_tmux_sessions
            let timestamp = context
                .all_tmux_sessions
                .iter()
                .find(|s| &s.name == session_name)
                .map(|s| s.last_attached);

            let mut session_item = SessionItem::new(
                session_name.clone(),
                "scratch".to_string(),
                self.priority(),
                metadata,
            ).with_current(is_current)
              .with_active(true);

            if let Some(ts) = timestamp {
                session_item = session_item.with_timestamp(ts);
            }

            sessions.push(session_item);
        }

        Ok(sessions)
    }

    async fn resolve(&self, session_name: &str, _context: &SessionContext) -> Result<SessionMetadata> {
        if self.tmux.has_session(session_name).await {
            let session_path = self.tmux.get_session_path(session_name).await?;

            let mut metadata = SessionMetadata::new("scratch".to_string())
                .with_exists(true);

            if let Some(path) = session_path {
                metadata = metadata.with_path(path);
            }

            Ok(metadata)
        } else {
            Ok(SessionMetadata::new("scratch".to_string()).with_exists(false))
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
                "\x1b[1;33m󱗽 Scratch Session: {}\x1b[0m\n\nThis session will be created when selected.",
                session_name
            ));
        }

        // Get session info
        let (windows, _attached) = self.tmux.get_session_info(session_name).await?;

        let mut preview = format!(
            "\x1b[1;33m󱗽 {}\x1b[0m (\x1b[1;33m{} windows\x1b[0m)\n",
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
            "\x1b[1;32m󱗽\x1b[0m - Scratch session (green when active)".to_string(),
        ]
    }
}