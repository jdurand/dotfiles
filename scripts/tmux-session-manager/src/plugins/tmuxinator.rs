use anyhow::{anyhow, Result};
use async_trait::async_trait;
use std::path::Path;
use tokio::process::Command;

use crate::core::{session::{SessionContext, SessionItem, SessionMetadata}, tmux::TmuxClient};
use crate::plugins::SessionPlugin;

pub struct TmuxinatorPlugin {
    tmux: TmuxClient,
    config_dirs: Vec<String>,
}

impl TmuxinatorPlugin {
    pub fn new() -> Self {
        let mut config_dirs = Vec::new();

        // Default tmuxinator config locations
        if let Some(home) = dirs::home_dir() {
            config_dirs.push(format!("{}/.config/tmuxinator", home.display()));
            config_dirs.push(format!("{}/.tmuxinator", home.display()));
        }

        // Check XDG_CONFIG_HOME
        if let Ok(xdg_config) = std::env::var("XDG_CONFIG_HOME") {
            config_dirs.push(format!("{}/tmuxinator", xdg_config));
        }

        Self {
            tmux: TmuxClient::new(),
            config_dirs,
        }
    }

    async fn find_tmuxinator_configs(&self) -> Result<Vec<(String, String)>> {
        let mut configs = Vec::new();

        for config_dir in &self.config_dirs {
            let config_path = Path::new(config_dir);
            if !config_path.exists() {
                continue;
            }

            let mut entries = tokio::fs::read_dir(config_path).await?;
            while let Some(entry) = entries.next_entry().await? {
                let path = entry.path();
                if let Some(extension) = path.extension() {
                    if extension == "yml" || extension == "yaml" {
                        if let Some(file_stem) = path.file_stem() {
                            if let Some(name) = file_stem.to_str() {
                                configs.push((name.to_string(), path.to_string_lossy().to_string()));
                            }
                        }
                    }
                }
            }
        }

        Ok(configs)
    }

    async fn is_tmuxinator_available(&self) -> bool {
        Command::new("tmuxinator")
            .arg("version")
            .output()
            .await
            .map(|output| output.status.success())
            .unwrap_or(false)
    }

    async fn read_config_summary(&self, config_path: &str) -> Result<String> {
        let content = tokio::fs::read_to_string(config_path).await?;

        // Simple YAML parsing to extract some basic info
        let mut summary = String::new();
        let mut root_dir = None;
        let mut windows = Vec::new();

        for line in content.lines() {
            let line = line.trim();

            if line.starts_with("root:") {
                root_dir = line.strip_prefix("root:").map(|s| s.trim().trim_matches('"'));
            } else if line.starts_with("windows:") {
                continue; // Start of windows section
            } else if line.starts_with("- ") || line.starts_with("  - ") {
                // Window definition
                let window_def = line.trim_start_matches("- ").trim();
                if let Some(colon_pos) = window_def.find(':') {
                    let window_name = &window_def[..colon_pos];
                    windows.push(window_name.trim().to_string());
                } else {
                    windows.push(window_def.to_string());
                }
            }
        }

        if let Some(root) = root_dir {
            summary.push_str(&format!("Root: {}\n", root));
        }

        if !windows.is_empty() {
            summary.push_str(&format!("Windows: {}\n", windows.join(", ")));
        }

        Ok(summary)
    }
}

#[async_trait]
impl SessionPlugin for TmuxinatorPlugin {
    fn name(&self) -> &str {
        "tmuxinator"
    }

    fn description(&self) -> &str {
        "Tmuxinator configuration sessions"
    }

    fn priority(&self) -> u32 {
        50
    }

    fn dependencies(&self) -> Vec<&str> {
        vec!["tmuxinator"]
    }

    async fn discover(&self, context: &SessionContext) -> Result<Vec<SessionItem>> {
        if !self.is_tmuxinator_available().await {
            return Ok(Vec::new());
        }

        let configs = self.find_tmuxinator_configs().await?;
        let mut sessions = Vec::new();

        for (config_name, config_path) in configs {
            // Check if a session with this name already exists
            let is_active = context
                .all_tmux_sessions
                .iter()
                .any(|s| s.name == config_name);

            let is_current = context.current_session.as_ref() == Some(&config_name);

            let metadata = SessionMetadata::new("tmuxinator".to_string())
                .with_exists(is_active)
                .with_path(config_path.clone())
                .with_property("config_path".to_string(), config_path);

            let mut session_item = SessionItem::new(
                config_name,
                "tmuxinator".to_string(),
                self.priority(),
                metadata,
            ).with_current(is_current)
              .with_active(is_active);

            // If session is active, get its timestamp
            if is_active {
                if let Some(tmux_session) = context.all_tmux_sessions
                    .iter()
                    .find(|s| s.name == session_item.name) {
                    session_item = session_item.with_timestamp(tmux_session.last_attached);
                }
            }

            sessions.push(session_item);
        }

        Ok(sessions)
    }

    async fn resolve(&self, session_name: &str, _context: &SessionContext) -> Result<SessionMetadata> {
        let configs = self.find_tmuxinator_configs().await?;

        for (config_name, config_path) in configs {
            if config_name == session_name {
                let is_active = self.tmux.has_session(session_name).await;

                return Ok(SessionMetadata::new("tmuxinator".to_string())
                    .with_exists(is_active)
                    .with_path(config_path.clone())
                    .with_property("config_path".to_string(), config_path));
            }
        }

        Err(anyhow!("Tmuxinator config not found for session: {}", session_name))
    }

    async fn switch(&self, session_name: &str, _metadata: &SessionMetadata) -> Result<()> {
        if self.tmux.has_session(session_name).await {
            // Session already exists, just switch to it
            if TmuxClient::is_inside_tmux() {
                self.tmux.switch_client(session_name).await
            } else {
                self.tmux.attach_session(session_name).await
            }
        } else {
            // Start tmuxinator session
            let output = Command::new("tmuxinator")
                .args(&["start", session_name])
                .output()
                .await?;

            if !output.status.success() {
                let stderr = String::from_utf8_lossy(&output.stderr);
                return Err(anyhow!("Failed to start tmuxinator session: {}", stderr));
            }

            // Attach to the newly created session
            if TmuxClient::is_inside_tmux() {
                self.tmux.switch_client(session_name).await
            } else {
                self.tmux.attach_session(session_name).await
            }
        }
    }

    async fn start(&self, session_name: &str, _metadata: &SessionMetadata) -> Result<()> {
        // Start in background without attaching
        let output = Command::new("tmuxinator")
            .args(&["start", session_name, "--detach"])
            .output()
            .await?;

        if !output.status.success() {
            let stderr = String::from_utf8_lossy(&output.stderr);
            return Err(anyhow!("Failed to start tmuxinator session in background: {}", stderr));
        }

        Ok(())
    }

    async fn preview(&self, session_name: &str, metadata: &SessionMetadata) -> Result<String> {
        let mut preview = format!("\x1b[0;37m● Tmuxinator: {}\x1b[0m\n\n", session_name);

        if let Some(config_path) = metadata.get_property("config_path") {
            preview.push_str(&format!("\x1b[1;33mConfig file:\x1b[0m\n{}\n\n", config_path));

            // Try to read and parse config summary
            match self.read_config_summary(config_path).await {
                Ok(summary) => {
                    if !summary.is_empty() {
                        preview.push_str("\x1b[1;33mConfiguration:\x1b[0m\n");
                        for line in summary.lines() {
                            preview.push_str(&format!("  {}\n", line));
                        }
                        preview.push('\n');
                    }
                }
                Err(_) => {
                    preview.push_str("Could not read configuration details\n\n");
                }
            }

            if metadata.exists {
                preview.push_str("\x1b[1;32mSession is currently active\x1b[0m\n");

                // Try to show session info
                if let Ok((windows, _)) = self.tmux.get_session_info(session_name).await {
                    preview.push_str(&format!("Windows: {}\n", windows));
                }
            } else {
                preview.push_str("\x1b[1;33mSession will be started from configuration\x1b[0m\n");
            }
        } else {
            preview.push_str("Configuration file not found\n");
        }

        Ok(preview)
    }

    fn get_help_text(&self) -> Vec<String> {
        vec![
            "\x1b[0;90m●\x1b[0m - Tmuxinator config (grey)".to_string(),
        ]
    }
}