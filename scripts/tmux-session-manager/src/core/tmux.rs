use anyhow::{anyhow, Context, Result};
use chrono::{TimeZone, Utc};
use tokio::process::Command;

use crate::core::session::{SessionContext, TmuxSession};

pub struct TmuxClient {
    socket_path: Option<String>,
}

impl TmuxClient {
    pub fn new() -> Self {
        Self { socket_path: None }
    }


    pub async fn get_session_context(&self) -> Result<SessionContext> {
        let all_sessions = self.list_all_sessions().await?;
        let current_session = self.get_current_session().await.ok();

        let (active_sessions, scratch_sessions) = self.categorize_sessions(&all_sessions, &current_session);

        Ok(SessionContext::new()
            .with_current_session(current_session)
            .with_active_sessions(active_sessions)
            .with_scratch_sessions(scratch_sessions)
            .with_all_tmux_sessions(all_sessions))
    }

    async fn list_all_sessions(&self) -> Result<Vec<TmuxSession>> {
        let output = self
            .execute_tmux_command(&[
                "list-sessions",
                "-F",
                "#{session_last_attached}:#{session_name}:#{session_windows}:#{session_attached}",
            ])
            .await?;

        let mut sessions = Vec::new();
        for line in output.lines() {
            if let Some(session) = self.parse_session_line(line)? {
                sessions.push(session);
            }
        }

        // Sort by last attached time (most recent first)
        sessions.sort_by(|a, b| b.last_attached.cmp(&a.last_attached));

        Ok(sessions)
    }

    async fn get_current_session(&self) -> Result<String> {
        let output = self
            .execute_tmux_command(&["display-message", "-p", "#{session_name}"])
            .await?;

        Ok(output.trim().to_string())
    }

    pub async fn get_session_path(&self, session_name: &str) -> Result<Option<String>> {
        let output = self
            .execute_tmux_command(&[
                "display-message",
                "-t",
                session_name,
                "-p",
                "#{pane_current_path}",
            ])
            .await;

        match output {
            Ok(path) => Ok(Some(path.trim().to_string())),
            Err(_) => Ok(None),
        }
    }

    pub async fn has_session(&self, session_name: &str) -> bool {
        self.execute_tmux_command(&["has-session", "-t", session_name])
            .await
            .is_ok()
    }

    pub async fn switch_client(&self, session_name: &str) -> Result<()> {
        self.execute_tmux_command(&["switch-client", "-t", session_name])
            .await?;
        Ok(())
    }

    pub async fn attach_session(&self, session_name: &str) -> Result<()> {
        self.execute_tmux_command(&["attach-session", "-t", session_name])
            .await?;
        Ok(())
    }

    pub async fn new_session(&self, session_name: &str, path: Option<&str>) -> Result<()> {
        let mut args = vec!["new-session", "-d", "-s", session_name];

        if let Some(path) = path {
            args.extend_from_slice(&["-c", path]);
        }

        self.execute_tmux_command(&args).await?;
        Ok(())
    }

    pub async fn kill_session(&self, session_name: &str) -> Result<()> {
        self.execute_tmux_command(&["kill-session", "-t", session_name])
            .await?;
        Ok(())
    }


    pub async fn capture_pane(&self, session_name: &str) -> Result<String> {
        // Get the active window and pane
        let window_output = self
            .execute_tmux_command(&[
                "list-windows",
                "-t",
                session_name,
                "-f",
                "#{window_active}",
                "-F",
                "#{window_index}",
            ])
            .await?;

        let active_window = window_output.lines().next()
            .ok_or_else(|| anyhow!("No active window found"))?;

        let pane_output = self
            .execute_tmux_command(&[
                "list-panes",
                "-t",
                &format!("{}:{}", session_name, active_window),
                "-f",
                "#{pane_active}",
                "-F",
                "#{pane_index}",
            ])
            .await?;

        let active_pane = pane_output.lines().next()
            .ok_or_else(|| anyhow!("No active pane found"))?;

        // Capture the pane content
        let target = format!("{}:{}.{}", session_name, active_window, active_pane);
        let content = self
            .execute_tmux_command(&["capture-pane", "-ep", "-t", &target])
            .await?;

        Ok(content)
    }

    pub async fn get_session_info(&self, session_name: &str) -> Result<(u32, bool)> {
        let output = self
            .execute_tmux_command(&[
                "display-message",
                "-t",
                session_name,
                "-p",
                "#{session_windows}:#{session_attached}",
            ])
            .await?;

        let line = output.trim();
        let parts: Vec<&str> = line.split(':').collect();
        if parts.len() != 2 {
            return Err(anyhow!("Invalid session info format: {}", line));
        }

        let windows = parts[0].parse::<u32>()
            .context("Invalid window count")?;
        let attached = parts[1] == "1";

        Ok((windows, attached))
    }

    async fn execute_tmux_command(&self, args: &[&str]) -> Result<String> {
        let mut cmd = Command::new("tmux");

        if let Some(socket) = &self.socket_path {
            cmd.args(&["-S", socket]);
        }

        cmd.args(args);

        let output = cmd
            .output()
            .await
            .context("Failed to execute tmux command")?;

        if !output.status.success() {
            let stderr = String::from_utf8_lossy(&output.stderr);
            return Err(anyhow!("tmux command failed: {}", stderr));
        }

        Ok(String::from_utf8_lossy(&output.stdout).to_string())
    }

    fn parse_session_line(&self, line: &str) -> Result<Option<TmuxSession>> {
        let parts: Vec<&str> = line.split(':').collect();
        if parts.len() < 4 {
            return Ok(None);
        }

        let timestamp_str = parts[0];
        let name = parts[1].to_string();
        let windows = parts[2].parse::<u32>()
            .context("Invalid window count")?;
        let attached = parts[3] == "1";

        let last_attached = if let Ok(timestamp) = timestamp_str.parse::<i64>() {
            Utc.timestamp_opt(timestamp, 0)
                .single()
                .unwrap_or_else(Utc::now)
        } else {
            Utc::now()
        };

        Ok(Some(TmuxSession {
            name,
            last_attached,
            windows,
            attached,
            current_path: None, // Will be populated separately if needed
        }))
    }

    fn categorize_sessions(&self, sessions: &[TmuxSession], current_session: &Option<String>) -> (Vec<String>, Vec<String>) {
        let mut active_sessions = Vec::new();
        let mut scratch_sessions = Vec::new();

        // Collect sessions first, excluding current session from active_sessions
        for session in sessions {
            // Skip current session - it should not be in active_sessions
            if let Some(current) = current_session {
                if session.name == *current {
                    continue;
                }
            }

            if session.name.contains("scratch") {
                scratch_sessions.push(session.name.clone());
            } else {
                active_sessions.push(session.name.clone());
            }
        }

        // Sort active sessions by last_attached (most recent first)
        // We need to sort by referencing the original sessions data
        active_sessions.sort_by(|a, b| {
            let a_time = sessions.iter().find(|s| &s.name == a).unwrap().last_attached;
            let b_time = sessions.iter().find(|s| &s.name == b).unwrap().last_attached;
            b_time.cmp(&a_time) // Reverse order for most recent first
        });

        // Sort scratch sessions by last_attached too
        scratch_sessions.sort_by(|a, b| {
            let a_time = sessions.iter().find(|s| &s.name == a).unwrap().last_attached;
            let b_time = sessions.iter().find(|s| &s.name == b).unwrap().last_attached;
            b_time.cmp(&a_time) // Reverse order for most recent first
        });

        (active_sessions, scratch_sessions)
    }

    pub fn is_inside_tmux() -> bool {
        std::env::var("TMUX").is_ok()
    }
}