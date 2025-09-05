use anyhow::{anyhow, Result};
use async_trait::async_trait;
use std::path::Path;
use tokio::process::Command;

use crate::core::{session::{SessionContext, SessionItem, SessionMetadata}, tmux::TmuxClient};
use crate::plugins::SessionPlugin;

pub struct WorktreePlugin {
    tmux: TmuxClient,
}

impl WorktreePlugin {
    pub fn new() -> Self {
        Self {
            tmux: TmuxClient::new(),
        }
    }

    async fn get_current_repo_root(&self, context: &SessionContext) -> Result<Option<String>> {
        // Try to get current session directory first
        let current_dir = if let Some(current_session) = &context.current_session {
            self.tmux.get_session_path(current_session).await?
        } else {
            Some(std::env::current_dir()?.to_string_lossy().to_string())
        };

        if let Some(dir) = current_dir {
            let output = Command::new("git")
                .args(&["rev-parse", "--show-toplevel"])
                .current_dir(&dir)
                .output()
                .await;

            if let Ok(output) = output {
                if output.status.success() {
                    let root = String::from_utf8_lossy(&output.stdout)
                        .trim()
                        .to_string();
                    return Ok(Some(root));
                }
            }
        }

        Ok(None)
    }

    async fn list_worktrees(&self, repo_root: &str) -> Result<Vec<(String, String)>> {
        let output = Command::new("git")
            .args(&["worktree", "list", "--porcelain"])
            .current_dir(repo_root)
            .output()
            .await?;

        if !output.status.success() {
            return Err(anyhow!("Failed to list git worktrees"));
        }

        let output_str = String::from_utf8_lossy(&output.stdout);
        let mut worktrees = Vec::new();
        let mut current_path = None;
        let mut current_branch = None;

        for line in output_str.lines() {
            if line.starts_with("worktree ") {
                current_path = Some(line.strip_prefix("worktree ").unwrap().to_string());
            } else if line.starts_with("branch ") {
                let branch = line.strip_prefix("branch refs/heads/")
                    .unwrap_or(line.strip_prefix("branch ").unwrap_or("unknown"));
                current_branch = Some(branch.to_string());
            }

            if let (Some(path), Some(_branch)) = (&current_path, &current_branch) {
                let worktree_name = Path::new(path)
                    .file_name()
                    .and_then(|n| n.to_str())
                    .unwrap_or("unknown")
                    .to_string();

                worktrees.push((path.clone(), worktree_name));
                current_path = None;
                current_branch = None;
            }
        }

        Ok(worktrees)
    }

    async fn is_session_in_worktree(&self, session_name: &str) -> Result<bool> {
        if let Some(session_path) = self.tmux.get_session_path(session_name).await? {
            let git_file = Path::new(&session_path).join(".git");
            if git_file.exists() {
                // Check if .git is a file (worktree) or directory (regular repo)
                if git_file.is_file() {
                    match tokio::fs::read_to_string(&git_file).await {
                        Ok(contents) => return Ok(contents.contains("gitdir:")),
                        Err(_) => return Ok(false), // Can't read file, assume not a worktree
                    }
                } else {
                    // .git is a directory, so this is a regular repo, not a worktree
                    return Ok(false);
                }
            }
        }
        Ok(false)
    }

    /// Generate a tmux-safe session name (tmux doesn't like names starting with dots)
    fn get_tmux_safe_name(&self, session_name: &str) -> String {
        if session_name.starts_with('.') {
            session_name[1..].to_string() // Remove the leading dot
        } else {
            session_name.to_string()
        }
    }
}

#[async_trait]
impl SessionPlugin for WorktreePlugin {
    fn name(&self) -> &str {
        "worktree"
    }

    fn description(&self) -> &str {
        "Git worktree sessions"
    }

    fn priority(&self) -> u32 {
        5 // Higher priority than active sessions
    }

    fn dependencies(&self) -> Vec<&str> {
        vec!["git"]
    }

    async fn discover(&self, context: &SessionContext) -> Result<Vec<SessionItem>> {
        let mut sessions = Vec::new();

        // First, check existing tmux sessions for worktrees
        let mut discovered_worktrees = Vec::new();
        for tmux_session in &context.all_tmux_sessions {
            if self.is_session_in_worktree(&tmux_session.name).await? {
                let is_current = context.current_session.as_ref() == Some(&tmux_session.name);

                let metadata = SessionMetadata::new("worktree".to_string())
                    .with_exists(true);

                let session_item = SessionItem::new(
                    tmux_session.name.clone(),
                    "worktree".to_string(),
                    self.priority(),
                    metadata,
                ).with_current(is_current)
                  .with_active(true)
                  .with_timestamp(tmux_session.last_attached);

                sessions.push(session_item);
                discovered_worktrees.push(tmux_session.name.clone());
            }
        }

        // Then discover worktrees that don't have sessions yet
        if let Ok(Some(repo_root)) = self.get_current_repo_root(context).await {
            if let Ok(worktrees) = self.list_worktrees(&repo_root).await {
                for (worktree_path, worktree_name) in worktrees {
                    // Check both the clean name and tmux-safe name for existing sessions
                    let tmux_safe_name = self.get_tmux_safe_name(&worktree_name);
                    if discovered_worktrees.contains(&worktree_name) ||
                       discovered_worktrees.contains(&tmux_safe_name) {
                        continue;
                    }

                    // Skip the main repo (check if .git is a directory, not a file)
                    let git_path = Path::new(&worktree_path).join(".git");
                    if git_path.is_dir() {
                        continue; // This is the main repo, not a worktree
                    }

                    let metadata = SessionMetadata::new("worktree".to_string())
                        .with_exists(false)
                        .with_path(worktree_path);

                    // Use the clean worktree name for display, not the tmux-safe name
                    let session_item = SessionItem::new(
                        worktree_name,
                        "worktree".to_string(),
                        self.priority(),
                        metadata,
                    ).with_active(false);

                    sessions.push(session_item);
                }
            }
        }

        Ok(sessions)
    }

    async fn resolve(&self, session_name: &str, context: &SessionContext) -> Result<SessionMetadata> {
        // Check if session already exists (try both display name and tmux-safe name)
        let tmux_safe_name = self.get_tmux_safe_name(session_name);
        let session_exists = self.tmux.has_session(session_name).await ||
                            self.tmux.has_session(&tmux_safe_name).await;

        if session_exists {
            // Try to get session path using either display name or tmux-safe name
            let session_path = match self.tmux.get_session_path(session_name).await? {
                Some(path) => Some(path),
                None => self.tmux.get_session_path(&tmux_safe_name).await.ok().flatten(),
            };

            if let Some(session_path) = session_path {
                let git_file = Path::new(&session_path).join(".git");
                if git_file.exists() {
                    let contents = tokio::fs::read_to_string(&git_file).await?;
                    if contents.contains("gitdir:") {
                        let mut metadata = SessionMetadata::new("worktree".to_string())
                            .with_exists(true)
                            .with_path(session_path.clone());

                        // Get branch info
                        let branch_output = Command::new("git")
                            .args(&["branch", "--show-current"])
                            .current_dir(&session_path)
                            .output()
                            .await;

                        if let Ok(output) = branch_output {
                            if output.status.success() {
                                let branch = String::from_utf8_lossy(&output.stdout)
                                    .trim()
                                    .to_string();
                                metadata = metadata.with_property("branch".to_string(), branch);
                            }
                        }

                        return Ok(metadata);
                    }
                }
            }
        }

        // Session doesn't exist, try to find the worktree path
        if let Ok(Some(repo_root)) = self.get_current_repo_root(context).await {
            if let Ok(worktrees) = self.list_worktrees(&repo_root).await {
                for (worktree_path, worktree_name) in worktrees {
                    if worktree_name == session_name {
                        return Ok(SessionMetadata::new("worktree".to_string())
                            .with_exists(false)
                            .with_path(worktree_path));
                    }
                }
            }
        }

        Err(anyhow!("Worktree not found for session: {}", session_name))
    }

    async fn switch(&self, session_name: &str, metadata: &SessionMetadata) -> Result<()> {
        let worktree_path = metadata.path.as_ref()
            .ok_or_else(|| anyhow!("No worktree path found for session: {}", session_name))?;

        if !Path::new(worktree_path).exists() {
            return Err(anyhow!("Worktree path does not exist: {}", worktree_path));
        }

        // Use tmux-safe name for actual tmux operations
        let tmux_session_name = self.get_tmux_safe_name(session_name);

        if self.tmux.has_session(&tmux_session_name).await {
            // Session exists, just switch
            if TmuxClient::is_inside_tmux() {
                self.tmux.switch_client(&tmux_session_name).await
            } else {
                self.tmux.attach_session(&tmux_session_name).await
            }
        } else {
            // Create new session in worktree directory with tmux-safe name
            self.tmux.new_session(&tmux_session_name, Some(worktree_path)).await?;

            if TmuxClient::is_inside_tmux() {
                self.tmux.switch_client(&tmux_session_name).await
            } else {
                self.tmux.attach_session(&tmux_session_name).await
            }
        }
    }

    async fn preview(&self, session_name: &str, metadata: &SessionMetadata) -> Result<String> {
        let mut preview = format!("\x1b[0;34mGit Worktree: {}\x1b[0m\n\n", session_name);

        if let Some(worktree_path) = &metadata.path {
            preview.push_str(&format!("\x1b[1;33mWorktree path:\x1b[0m\n{}\n\n", worktree_path));

            if Path::new(worktree_path).exists() {
                // Get branch info
                let branch_output = Command::new("git")
                    .args(&["branch", "--show-current"])
                    .current_dir(worktree_path)
                    .output()
                    .await;

                if let Ok(output) = branch_output {
                    if output.status.success() {
                        let branch = String::from_utf8_lossy(&output.stdout).trim().to_string();
                        preview.push_str(&format!("\x1b[1;33mBranch info:\x1b[0m\n{}\n\n", branch));
                    }
                }

                // Get recent commits
                let log_output = Command::new("git")
                    .args(&["log", "--oneline", "-5"])
                    .current_dir(worktree_path)
                    .output()
                    .await;

                if let Ok(output) = log_output {
                    if output.status.success() {
                        let commits = String::from_utf8_lossy(&output.stdout);
                        preview.push_str("\x1b[1;33mRecent commits:\x1b[0m\n");
                        for line in commits.lines() {
                            preview.push_str(&format!("  {}\n", line));
                        }
                        preview.push('\n');
                    }
                }

                // Get working directory status
                let status_output = Command::new("git")
                    .args(&["status", "--porcelain"])
                    .current_dir(worktree_path)
                    .output()
                    .await;

                if let Ok(output) = status_output {
                    if output.status.success() {
                        let status = String::from_utf8_lossy(&output.stdout);
                        preview.push_str("\x1b[1;33mWorking directory status:\x1b[0m\n");
                        if status.is_empty() {
                            preview.push_str("  Clean working directory\n");
                        } else {
                            for (i, line) in status.lines().enumerate() {
                                if i >= 10 { break; } // Limit to first 10 files
                                preview.push_str(&format!("  {}\n", line));
                            }
                        }
                    }
                }
            } else {
                preview.push_str("Worktree path does not exist\n");
            }
        } else {
            preview.push_str("Worktree path not found\n");
        }

        Ok(preview)
    }

    fn get_help_text(&self) -> Vec<String> {
        vec![
            "\x1b[0;34m●\x1b[0m - Active worktree session (blue)".to_string(),
            "\x1b[0;34m○\x1b[0m - Inactive worktree (blue outline)".to_string(),
        ]
    }
}
