use anyhow::Result;
use std::io::Write;
use std::process::Stdio;
use tempfile::NamedTempFile;
use tokio::process::Command;
use tokio::io::AsyncWriteExt;

use crate::core::tmux::TmuxClient;
use crate::plugins::PluginManager;
use crate::core::session::SessionContext;

pub struct FzfInterface<'a> {
    pub plugin_manager: &'a PluginManager,
    preview_enabled: bool,
    force_no_popup: bool,
}

#[derive(Debug, Clone)]
pub struct FzfResult {
    pub key: Option<String>,
    pub selection: Option<String>,
}

impl<'a> FzfInterface<'a> {
    pub fn new(plugin_manager: &'a PluginManager) -> Self {
        Self {
            plugin_manager,
            preview_enabled: true, // Default enabled
            force_no_popup: false, // Default to use popup when inside tmux
        }
    }

    pub fn with_preview_enabled(mut self, enabled: bool) -> Self {
        self.preview_enabled = enabled;
        self
    }

    pub fn with_force_no_popup(mut self, force: bool) -> Self {
        self.force_no_popup = force;
        self
    }

    pub async fn show_session_selector(&mut self, context: &SessionContext) -> Result<FzfResult> {
        let sessions = self.plugin_manager.discover_all_sessions(context).await?;

        if sessions.is_empty() {
            return Ok(FzfResult {
                key: None,
                selection: None,
            });
        }

        let formatted_sessions: Vec<String> = sessions
            .iter()
            .map(|s| s.format_for_display())
            .collect();

        if TmuxClient::is_inside_tmux() && !self.force_no_popup {
            self.show_tmux_popup(formatted_sessions, context).await
        } else {
            self.show_regular_fzf(formatted_sessions, context).await
        }
    }

    async fn show_tmux_popup(&mut self, sessions: Vec<String>, context: &SessionContext) -> Result<FzfResult> {
        // Create temporary files for input and output
        let mut input_file = NamedTempFile::new()?;
        let output_file = NamedTempFile::new()?;
        let preview_script = NamedTempFile::new()?;

        // Write sessions to input file
        for session in &sessions {
            writeln!(input_file, "{}", session)?;
        }
        input_file.flush()?;

        // Create preview script
        self.create_preview_script(&preview_script, context).await?;

        // Prepare fzf command for tmux popup
        let preview_window = if self.preview_enabled {
            "right:50%:wrap"
        } else {
            "hidden"
        };

        let title = self.build_title().await?;

        let tmux_cmd = format!(
            r#"cat '{}' | fzf \
                --prompt='{}: ' \
                --ansi \
                --reverse \
                --border \
                --expect=ctrl-x,ctrl-r,ctrl-s,ctrl-n,ctrl-p \
                --preview='{} {{}}' \
                --preview-window={} \
                --bind='ctrl-p:toggle-preview+change-preview({} {{}})+change-preview-window(right:50%:wrap)' \
                --bind='?:change-preview({} {{}} HELP)+change-preview-window(right:50%:wrap)' \
                --bind='ctrl-d:preview-page-down' \
                --bind='ctrl-u:preview-page-up' > '{}'"#,
            input_file.path().display(),
            title,
            preview_script.path().display(),
            preview_window,
            preview_script.path().display(),
            preview_script.path().display(),
            output_file.path().display()
        );

        // Execute tmux popup
        let output = Command::new("tmux")
            .args(&[
                "display-popup",
                "-E",
                "-w", "60%",
                "-h", "40%",
                &tmux_cmd
            ])
            .output()
            .await?;

        if !output.status.success() {
            return Ok(FzfResult {
                key: None,
                selection: None,
            });
        }

        // Read result
        let result = tokio::fs::read_to_string(output_file.path()).await?;
        self.parse_fzf_result(&result)
    }

    async fn show_regular_fzf(&mut self, sessions: Vec<String>, _context: &SessionContext) -> Result<FzfResult> {
        let title = self.build_title().await?;

        let mut cmd = Command::new("fzf")
            .args(&[
                "--height=40%",
                "--border",
                &format!("--prompt={}: ", title),
                "--ansi",
                "--expect=ctrl-x,ctrl-r,ctrl-s,ctrl-n,ctrl-p",
                "--preview=echo -e 'Session Switcher Help\\n\\nKeybindings:\\n  Enter    - Switch to session\\n  Ctrl-x   - Kill session\\n  Ctrl-r   - Rename session\\n  Ctrl-n   - Create new session\\n  ?        - Toggle help\\n\\nSession Icons:\\n  ● - Active session\\n  → - Current session\\n  ● - Tmuxinator config (grey)\\n  ● - Git worktree (blue)\\n  󱗽 - Scratch session\\n\\nNavigation:\\n  Ctrl-j/k    - Move selection\\n  Esc         - Exit without selection'",
                "--preview-window=hidden",
                "--bind=?:toggle-preview"
            ])
            .stdin(Stdio::piped())
            .stdout(Stdio::piped())
            .stderr(Stdio::null())
            .spawn()?;

        // Write sessions to stdin
        if let Some(stdin) = cmd.stdin.take() {
            let mut stdin = tokio::io::BufWriter::new(stdin);
            for session in &sessions {
                use tokio::io::AsyncWriteExt;
                stdin.write_all(session.as_bytes()).await?;
                stdin.write_all(b"\n").await?;
            }
            stdin.flush().await?;
        }

        let output = cmd.wait_with_output().await?;

        if !output.status.success() {
            return Ok(FzfResult {
                key: None,
                selection: None,
            });
        }

        let result = String::from_utf8_lossy(&output.stdout);
        self.parse_fzf_result(&result)
    }

    async fn create_preview_script(&self, script_file: &NamedTempFile, _context: &SessionContext) -> Result<()> {
        // Get the path to the current Rust binary
        let current_exe = std::env::current_exe()?.display().to_string();

        let script_content = format!(r#"#!/bin/bash
selection="$1"
mode="$2"

# Extract session name from formatted display
session_name=$(echo "$selection" | sed -E 's/^[^●→○󱗽★]*[●→○󱗽★][^[:space:]]* ([^[:space:]]+).*/\1/')

case "$mode" in
    "HELP")
        # Call the Rust binary for colored help
        "{}" --help-preview 2>/dev/null || echo "Help unavailable"
        ;;
    *)
        # Call back to the Rust binary for preview generation
        "{}" --generate-preview "$session_name" "$selection" 2>/dev/null || echo "Preview unavailable for: $session_name"
        ;;
esac
"#, current_exe, current_exe);

        use std::os::unix::fs::PermissionsExt;
        tokio::fs::write(script_file.path(), script_content).await?;
        tokio::fs::set_permissions(script_file.path(), std::fs::Permissions::from_mode(0o755)).await?;
        Ok(())
    }

    async fn build_title(&self) -> Result<String> {
        let mut title = "Select session (?: help)".to_string();

        // Check for missing dependencies and add to title
        let missing_deps = self.check_missing_dependencies().await;
        if !missing_deps.is_empty() {
            title.push_str(&format!(" [missing {} dependencies]", missing_deps.len()));
        }

        Ok(title)
    }

    async fn check_missing_dependencies(&self) -> Vec<String> {
        let mut missing = Vec::new();
        let common_deps = ["tmuxinator", "git"];

        for dep in &common_deps {
            if !self.command_exists(dep).await {
                missing.push(dep.to_string());
            }
        }

        missing
    }

    async fn command_exists(&self, command: &str) -> bool {
        Command::new("which")
            .arg(command)
            .output()
            .await
            .map(|output| output.status.success())
            .unwrap_or(false)
    }

    fn parse_fzf_result(&self, result: &str) -> Result<FzfResult> {
        let lines: Vec<&str> = result.trim().lines().collect();

        if lines.is_empty() {
            return Ok(FzfResult {
                key: None,
                selection: None,
            });
        }

        if lines.len() == 1 {
            // Only selection, no key pressed
            Ok(FzfResult {
                key: None,
                selection: Some(lines[0].to_string()),
            })
        } else if lines.len() >= 2 {
            // Key and selection
            Ok(FzfResult {
                key: Some(lines[0].to_string()),
                selection: Some(lines[1].to_string()),
            })
        } else {
            Ok(FzfResult {
                key: None,
                selection: None,
            })
        }
    }

    pub fn extract_session_name(&self, formatted_selection: &str) -> String {
        // Extract session name from formatted display string
        // Simple approach: split by whitespace and take the second token (first is icon)
        let tokens: Vec<&str> = formatted_selection.split_whitespace().collect();

        if tokens.len() >= 2 {
            // Second token is the session name, might have suffix in parentheses
            let name_part = tokens[1];
            // Remove any plugin suffix in parentheses
            if let Some(open_paren) = name_part.find('(') {
                name_part[..open_paren].trim().to_string()
            } else {
                name_part.to_string()
            }
        } else {
            // Fallback: return the whole string
            formatted_selection.to_string()
        }
    }

    pub async fn switch_to_session(&self, session_name: &str, context: &SessionContext) -> Result<()> {
        self.plugin_manager.switch_to_session(session_name, context).await
    }

    pub async fn kill_session(&self, session_name: &str, context: &SessionContext) -> Result<()> {
        self.plugin_manager.kill_session(session_name, context).await
    }

    pub async fn start_session(&self, session_name: &str, context: &SessionContext) -> Result<()> {
        self.plugin_manager.start_session(session_name, context).await
    }

    pub async fn create_new_session(&self, _context: &SessionContext) -> Result<()> {
        // Prompt for new session name using fzf
        let prompt_result = self.prompt_for_session_name().await?;
        if let Some(session_name) = prompt_result {
            // Create the new session
            let tmux = TmuxClient::new();
            tmux.new_session(&session_name, None).await?;
        }
        Ok(())
    }

    async fn prompt_for_session_name(&self) -> Result<Option<String>> {
        if TmuxClient::is_inside_tmux() {
            // Use tmux command-prompt for input
            self.tmux_prompt("New session name:", "new-session -d -s '%%'").await
        } else {
            // Use read command for non-tmux environments
            self.shell_prompt("Enter new session name").await
        }
    }

    pub async fn rename_session(&self, old_session_name: &str, _context: &SessionContext) -> Result<()> {
        // Prompt for new session name using fzf
        let prompt_result = self.prompt_for_rename(old_session_name).await?;
        if let Some(new_session_name) = prompt_result {
            // Rename the session
            let tmux = TmuxClient::new();
            tmux.rename_session(old_session_name, &new_session_name).await?;
        }
        Ok(())
    }

    async fn prompt_for_rename(&self, current_name: &str) -> Result<Option<String>> {
        if TmuxClient::is_inside_tmux() {
            // Use tmux command-prompt for input with current name as default
            self.tmux_prompt_with_default(&format!("Rename '{}' to:", current_name), &format!("rename-session -t '{}' '{{}}'", current_name), current_name).await
        } else {
            // Use read command for non-tmux environments
            self.shell_prompt(&format!("Rename '{}' to", current_name)).await
        }
    }

    async fn tmux_prompt(&self, prompt: &str, _command_template: &str) -> Result<Option<String>> {
        // Use tmux display-popup with a simple input method
        self.tmux_popup_prompt(prompt, None).await
    }

    async fn tmux_prompt_with_default(&self, prompt: &str, _command_template: &str, default: &str) -> Result<Option<String>> {
        // Use tmux display-popup with default value
        self.tmux_popup_prompt(prompt, Some(default)).await
    }

    async fn tmux_popup_prompt(&self, prompt: &str, _default: Option<&str>) -> Result<Option<String>> {
        use std::process::Stdio;
        use tokio::process::Command;
        use tempfile::NamedTempFile;

        // Create a temporary file to store the result
        let result_file = NamedTempFile::new()?;
        let result_path = result_file.path().to_string_lossy();

        // Use tmux command-prompt instead of popup for better input handling
        let tmux_command = format!(
            "run-shell 'echo \"%%\" > \"{}\"'",
            result_path
        );

        let mut tmux_cmd = Command::new("tmux");
        tmux_cmd
            .arg("command-prompt")
            .arg("-p")
            .arg(&format!("{}: ", prompt))
            .arg(&tmux_command)
            .stdout(Stdio::null())
            .stderr(Stdio::null());

        let output = tmux_cmd.output().await?;

        // Small delay to allow file write to complete
        tokio::time::sleep(std::time::Duration::from_millis(100)).await;

        // Read the result from the temporary file
        if output.status.success() {
            if let Ok(result) = std::fs::read_to_string(result_path.as_ref()) {
                let input = result.trim();
                if !input.is_empty() {
                    return Ok(Some(input.to_string()));
                }
            }
        }

        Ok(None)
    }

    async fn shell_prompt(&self, prompt: &str) -> Result<Option<String>> {
        use std::io::Write;
        use std::process::{Command, Stdio};
        use std::fs::OpenOptions;

        // Try to open the controlling terminal directly
        if let Ok(mut tty) = OpenOptions::new().read(true).write(true).open("/dev/tty") {
            // Write prompt to tty
            writeln!(tty, "{}: ", prompt).ok();
            tty.flush().ok();

            // Use /dev/tty for both input and output to bypass stdio redirection
            let mut cmd = Command::new("bash");
            cmd.arg("-c")
               .arg("read input < /dev/tty && echo $input")
               .stdout(Stdio::piped());

            if let Ok(output) = cmd.output() {
                if output.status.success() {
                    let result = String::from_utf8_lossy(&output.stdout);
                    let input = result.trim();
                    if !input.is_empty() {
                        return Ok(Some(input.to_string()));
                    }
                }
            }
        }

        Ok(None)
    }
}
