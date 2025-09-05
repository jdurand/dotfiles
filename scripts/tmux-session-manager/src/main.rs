use anyhow::Result;
use clap::{Arg, Command};

mod config;
mod core;
mod plugins;

use config::Config;
use core::{
    tmux::TmuxClient,
    ui::FzfInterface,
};
use plugins::PluginManager;

#[tokio::main]
async fn main() -> Result<()> {
    let matches = Command::new("tmux-session-manager")
        .version("0.1.0")
        .author("Jim Durand <hello@jdurand.com>")
        .about("High-performance tmux session manager with plugin system")
        .arg(
            Arg::new("doctor")
                .long("doctor")
                .help("Check plugin health and dependencies")
                .action(clap::ArgAction::SetTrue),
        )
        .arg(
            Arg::new("info")
                .long("info")
                .help("Show session info and troubleshooting")
                .action(clap::ArgAction::SetTrue),
        )
        .arg(
            Arg::new("no-popup")
                .long("no-popup")
                .help("Force regular fzf instead of tmux popup")
                .action(clap::ArgAction::SetTrue),
        )
        .arg(
            Arg::new("generate-preview")
                .long("generate-preview")
                .help("Generate preview for a session")
                .value_names(["SESSION", "SELECTION"])
                .num_args(2),
        )
        .arg(
            Arg::new("help-preview")
                .long("help-preview")
                .help("Show help preview")
                .action(clap::ArgAction::SetTrue),
        )
        .get_matches();

    // Load configuration
    let mut config = Config::load().await?;

    // Initialize components
    let mut plugin_manager = PluginManager::new();

    // Load dynamic plugins
    let plugin_dir = config.get_plugin_dir();
    if let Err(e) = plugin_manager.load_dynamic_plugins(&plugin_dir).await {
        eprintln!("Warning: Failed to load dynamic plugins: {}", e);
    }

    let tmux = TmuxClient::new();

    // Handle command line arguments
    if matches.get_flag("doctor") {
        return doctor_command(&plugin_manager).await;
    }

    if matches.get_flag("info") {
        return info_command(&plugin_manager, &tmux).await;
    }

    if let Some(values) = matches.get_many::<String>("generate-preview") {
        let values: Vec<&String> = values.collect();
        if values.len() == 2 {
            return generate_preview_command(&plugin_manager, &tmux, values[0], values[1]).await;
        }
    }

    if matches.get_flag("help-preview") {
        return help_preview_command().await;
    }

    // Main interactive mode
    run_interactive_mode(&mut config, plugin_manager, tmux, matches.get_flag("no-popup")).await
}

async fn run_interactive_mode(
    config: &mut Config,
    plugin_manager: PluginManager,
    tmux: TmuxClient,
    force_no_popup: bool,
) -> Result<()> {
    loop {
        // Get session context
        let context = tmux.get_session_context().await?;

        // Create UI interface
        let mut ui = FzfInterface::new(&plugin_manager)
            .with_preview_enabled(config.preview_enabled)
            .with_force_no_popup(force_no_popup);

        // Show session selector
        let result = ui.show_session_selector(&context).await?;

        if let Some(selection) = result.selection {
            let session_name = ui.extract_session_name(&selection);

            match result.key.as_deref() {
                Some("ctrl-x") => {
                    // Kill session and restart selector
                    if let Err(e) = ui.kill_session(&session_name, &context).await {
                        eprintln!("Failed to kill session: {}", e);
                        break;
                    }
                    continue; // Restart the selector
                }
                Some("ctrl-r") => {
                    eprintln!("Rename functionality not yet implemented");
                    break;
                }
                Some("ctrl-s") => {
                    if let Err(e) = ui.start_session(&session_name, &context).await {
                        eprintln!("Failed to start session: {}", e);
                        break;
                    }
                    continue; // Restart the selector to show the new session
                }
                Some("ctrl-n") => {
                    eprintln!("New session creation not yet implemented");
                    break;
                }
                Some("ctrl-p") => {
                    // Toggle preview and restart
                    config.toggle_preview().await?;
                    continue; // Restart with new preview state
                }
                _ => {
                    // Switch to session
                    ui.switch_to_session(&session_name, &context).await?;
                    break;
                }
            }
        } else {
            // User cancelled selection
            break;
        }
    }

    Ok(())
}

async fn doctor_command(plugin_manager: &PluginManager) -> Result<()> {
    println!("tmux-session-manager doctor");
    println!("==========================");
    println!();

    println!("Plugin Status:");
    println!("--------------");

    let plugins = plugin_manager.list_plugins();

    if plugins.is_empty() {
        println!("\x1b[0;31mNo plugins loaded\x1b[0m");
        return Ok(());
    }

    let mut error_count = 0;
    let all_dependencies = vec!["tmux", "fzf"]; // Core dependencies

    for (name, description, _priority) in &plugins {
        // TODO: Get plugin dependencies and check them
        println!("\x1b[1;32m✓ {}\x1b[0m: {}", name, description);
    }

    println!();
    println!("System Dependencies:");
    println!("-------------------");

    for dep in &all_dependencies {
        if command_exists(dep).await {
            println!("\x1b[1;32m✓ {}\x1b[0m: available", dep);
        } else {
            println!("\x1b[0;31m✗ {}\x1b[0m: not found", dep);
            error_count += 1;
        }
    }

    println!();
    println!("Summary:");
    println!("--------");
    println!("Plugins loaded: {}", plugins.len());

    if error_count == 0 {
        println!("\x1b[1;32mAll systems operational!\x1b[0m");
    } else {
        println!("\x1b[0;31mFound {} issue(s) that may affect functionality\x1b[0m", error_count);
    }

    Ok(())
}

async fn info_command(plugin_manager: &PluginManager, tmux: &TmuxClient) -> Result<()> {
    println!("tmux-session-manager info");
    println!("=========================");
    println!();

    println!("Environment:");
    println!("------------");

    let current_session = if TmuxClient::is_inside_tmux() {
        tmux.get_session_context().await?.current_session.unwrap_or_else(|| "NOT IN TMUX".to_string())
    } else {
        "NOT IN TMUX".to_string()
    };

    println!("Current tmux session: {}", current_session);
    println!("Working directory: {}", std::env::current_dir()?.display());
    println!();

    println!("Plugin loading:");
    println!("---------------");

    let plugins = plugin_manager.list_plugins();
    println!("Plugins loaded: {}", plugins.len());

    for (name, description, priority) in &plugins {
        println!("  ✓ {} (priority: {}) - {}", name, priority, description);
    }
    println!();

    println!("Session generation:");
    println!("------------------");

    let context = tmux.get_session_context().await?;
    let sessions = plugin_manager.discover_all_sessions(&context).await?;

    println!("Session count: {}", sessions.len());

    // Count sessions by plugin type
    let mut plugin_counts = std::collections::HashMap::new();
    for session in &sessions {
        *plugin_counts.entry(&session.plugin_name).or_insert(0) += 1;
    }

    for (plugin_name, count) in &plugin_counts {
        println!("{} sessions: {}", plugin_name, count);
    }
    println!();

    println!("Full session list:");
    for session in &sessions {
        println!("{}", session.format_for_display());
    }

    Ok(())
}

async fn generate_preview_command(plugin_manager: &PluginManager, tmux: &TmuxClient, session_name: &str, _selection: &str) -> Result<()> {
    let context = tmux.get_session_context().await?;
    let preview = plugin_manager.preview_session(session_name, &context).await?;
    println!("{}", preview);
    Ok(())
}

async fn help_preview_command() -> Result<()> {
    // Create a temporary PluginManager to get help text
    let plugin_manager = PluginManager::new();
    let plugin_help = plugin_manager.get_all_help_text();

    println!(r#"Session Switcher Help

Keybindings:
  Enter    - Switch to session
  Ctrl-x   - Kill session
  Ctrl-r   - Rename session
  Ctrl-s   - Start in background
  Ctrl-n   - Create new session
  Ctrl-p   - Toggle preview
  Ctrl-d   - Page down in preview
  Ctrl-u   - Page up in preview
  ?        - Show help

Session Icons:"#);

    // Print plugin-specific help with colors
    for help_line in plugin_help {
        println!("  {}", help_line);
    }

    println!(r#"
Navigation:
  ↑/↓ or j/k  - Move selection
  Esc         - Exit without selection

Additional Commands:
  --doctor - Check plugin health"#);
    Ok(())
}

async fn command_exists(command: &str) -> bool {
    tokio::process::Command::new("which")
        .arg(command)
        .output()
        .await
        .map(|output| output.status.success())
        .unwrap_or(false)
}


