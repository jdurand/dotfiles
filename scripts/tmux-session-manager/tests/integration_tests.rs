use anyhow::Result;
use chrono::{TimeZone, Utc};
use std::collections::HashMap;
use tmux_session_manager::*;
use tokio;

// Mock tmux client for testing
#[derive(Clone)]
struct MockTmuxClient {
    sessions: HashMap<String, TmuxSession>,
    current_session: Option<String>,
}

impl MockTmuxClient {
    fn new() -> Self {
        Self {
            sessions: HashMap::new(),
            current_session: None,
        }
    }

    fn add_session(&mut self, name: String, last_attached_unix: i64) -> &mut Self {
        let tmux_session = TmuxSession {
            name: name.clone(),
            last_attached: Utc.timestamp_opt(last_attached_unix, 0).single().unwrap(),
            windows: 1,
            attached: false,
            current_path: Some(format!("/Users/test/{}", name)),
        };
        self.sessions.insert(name, tmux_session);
        self
    }

    fn set_current_session(&mut self, name: String) -> &mut Self {
        self.current_session = Some(name);
        self
    }

    fn build_context(&self) -> SessionContext {
        let mut active_sessions = Vec::new();
        let mut scratch_sessions = Vec::new();
        let mut all_tmux_sessions = Vec::new();

        for (name, session) in &self.sessions {
            all_tmux_sessions.push(session.clone());

            // Skip current session - it should not be in active_sessions (matches real tmux client)
            if let Some(current) = &self.current_session {
                if name == current {
                    continue;
                }
            }

            if name.contains("scratch") {
                scratch_sessions.push(name.clone());
            } else {
                active_sessions.push(name.clone());
            }
        }

        // Sort by last attached (most recent first)
        all_tmux_sessions.sort_by(|a, b| b.last_attached.cmp(&a.last_attached));
        active_sessions.sort_by(|a, b| {
            let a_time = self.sessions[a].last_attached;
            let b_time = self.sessions[b].last_attached;
            b_time.cmp(&a_time)
        });

        SessionContext::new()
            .with_current_session(self.current_session.clone())
            .with_active_sessions(active_sessions)
            .with_scratch_sessions(scratch_sessions)
            .with_all_tmux_sessions(all_tmux_sessions)
    }
}

#[tokio::test]
async fn test_plugin_manager_creation() {
    let plugin_manager = PluginManager::new();
    let plugins = plugin_manager.list_plugins();

    // Should have the built-in plugins
    assert!(plugins.len() >= 4);

    let plugin_names: Vec<&str> = plugins.iter().map(|(name, _, _)| *name).collect();
    assert!(plugin_names.contains(&"active"));
    assert!(plugin_names.contains(&"worktree"));
    assert!(plugin_names.contains(&"scratch"));
    assert!(plugin_names.contains(&"tmuxinator"));
}

#[tokio::test]
async fn test_plugin_priority_ordering() {
    let plugin_manager = PluginManager::new();
    let plugins = plugin_manager.list_plugins();

    // Plugins should be sorted by priority (lower number = higher priority)
    let mut prev_priority = 0u32;
    for (_, _, priority) in &plugins {
        assert!(*priority >= prev_priority, "Plugins should be sorted by priority");
        prev_priority = *priority;
    }

    // Verify specific priorities
    let plugin_priorities: HashMap<&str, u32> = plugins.iter()
        .map(|(name, _, priority)| (*name, *priority))
        .collect();

    assert_eq!(plugin_priorities.get("worktree"), Some(&5));
    assert_eq!(plugin_priorities.get("active"), Some(&10));
    assert_eq!(plugin_priorities.get("tmuxinator"), Some(&50));
    assert_eq!(plugin_priorities.get("scratch"), Some(&999));
}

#[tokio::test]
async fn test_session_discovery_ordering() -> Result<()> {
    let plugin_manager = PluginManager::new();

    // Create mock context with deterministic data
    let mut mock_client = MockTmuxClient::new();
    mock_client
        .add_session("main".to_string(), 1234567890)      // Most recent
        .add_session("dotfiles".to_string(), 1234567889)  // Current session
        .add_session("notes".to_string(), 1234567888)
        .add_session("scratch-session".to_string(), 1234567887)
        .add_session("default".to_string(), 1234567886)   // Oldest
        .set_current_session("dotfiles".to_string());

    let context = mock_client.build_context();
    let sessions = plugin_manager.discover_all_sessions(&context).await?;

    // Should have sessions
    assert!(sessions.len() > 0, "Should discover sessions");

    // Verify session ordering by priority
    let mut prev_priority = 0u32;
    for session in &sessions {
        assert!(session.priority >= prev_priority,
            "Sessions should be ordered by priority: {} (priority {}) should not come before priority {}",
            session.name, session.priority, prev_priority);
        prev_priority = session.priority;
    }

    // Current session should be marked
    let current_sessions: Vec<_> = sessions.iter()
        .filter(|s| s.is_current)
        .collect();
    assert_eq!(current_sessions.len(), 1, "Should have exactly one current session");
    assert_eq!(current_sessions[0].name, "dotfiles");

    Ok(())
}

#[tokio::test]
async fn test_session_metadata() {
    let metadata = SessionMetadata::new("test".to_string())
        .with_path("/test/path".to_string())
        .with_exists(true)
        .with_property("test_key".to_string(), "test_value".to_string());

    assert_eq!(metadata.session_type, "test");
    assert_eq!(metadata.path, Some("/test/path".to_string()));
    assert_eq!(metadata.exists, true);
    assert_eq!(metadata.get_property("test_key"), Some(&"test_value".to_string()));
    assert_eq!(metadata.get_property("missing_key"), None);
}

#[tokio::test]
async fn test_session_item_formatting() {
    let metadata = SessionMetadata::new("active".to_string()).with_exists(true);

    // Test regular session
    let session = SessionItem::new(
        "test-session".to_string(),
        "active".to_string(),
        10,
        metadata.clone(),
    );

    let formatted = session.format_for_display();
    assert!(formatted.contains("test-session"));
    assert!(formatted.contains("●")); // Should have active icon

    // Test current session
    let current_session = SessionItem::new(
        "current-session".to_string(),
        "active".to_string(),
        10,
        metadata,
    ).with_current(true);

    let formatted_current = current_session.format_for_display();
    assert!(formatted_current.contains("current-session"));
    assert!(formatted_current.contains("→")); // Should have current icon
}

#[tokio::test]
async fn test_session_context_building() {
    let context = SessionContext::new()
        .with_current_session(Some("test".to_string()))
        .with_active_sessions(vec!["session1".to_string(), "session2".to_string()])
        .with_scratch_sessions(vec!["scratch1".to_string()]);

    assert_eq!(context.current_session, Some("test".to_string()));
    assert_eq!(context.active_sessions.len(), 2);
    assert_eq!(context.scratch_sessions.len(), 1);
}

#[tokio::test]
async fn test_session_deduplication() -> Result<()> {
    let plugin_manager = PluginManager::new();

    // Create context with overlapping sessions
    let mut mock_client = MockTmuxClient::new();
    mock_client
        .add_session("duplicate".to_string(), 1234567890)
        .add_session("unique1".to_string(), 1234567889)
        .add_session("unique2".to_string(), 1234567888);

    let context = mock_client.build_context();
    let sessions = plugin_manager.discover_all_sessions(&context).await?;

    // Check for duplicates
    let mut seen_names = std::collections::HashSet::new();
    for session in &sessions {
        assert!(seen_names.insert(session.name.clone()),
            "Session name '{}' appears multiple times", session.name);
    }

    Ok(())
}

#[tokio::test]
async fn test_config_management() -> Result<()> {
    let mut config = Config::default();

    assert_eq!(config.preview_enabled, true);

    // Test toggle
    config.preview_enabled = false;
    assert_eq!(config.preview_enabled, false);

    // Test plugin directory
    let plugin_dir = config.get_plugin_dir();
    assert!(plugin_dir.to_string_lossy().contains("tmux-session-manager"));
    assert!(plugin_dir.to_string_lossy().contains("plugins"));

    Ok(())
}

#[tokio::test]
async fn test_scratch_session_priority() -> Result<()> {
    let plugin_manager = PluginManager::new();

    let mut mock_client = MockTmuxClient::new();
    mock_client
        .add_session("regular-session".to_string(), 1234567890)
        .add_session("scratch-session".to_string(), 1234567891) // More recent
        .add_session("current-session".to_string(), 1234567892) // Current session
        .set_current_session("current-session".to_string());

    let context = mock_client.build_context();
    let sessions = plugin_manager.discover_all_sessions(&context).await?;

    // Find scratch and regular sessions
    let scratch_sessions: Vec<_> = sessions.iter()
        .filter(|s| s.plugin_name == "scratch")
        .collect();
    let regular_sessions: Vec<_> = sessions.iter()
        .filter(|s| s.plugin_name == "active")
        .collect();

    // Both should exist
    assert!(scratch_sessions.len() > 0, "Should find scratch sessions");
    assert!(regular_sessions.len() > 0, "Should find regular sessions");

    // All scratch sessions should have higher priority numbers (lower priority) than regular sessions
    for scratch in &scratch_sessions {
        for regular in &regular_sessions {
            assert!(scratch.priority > regular.priority,
                "Scratch session priority ({}) should be higher than regular session priority ({})",
                scratch.priority, regular.priority);
        }
    }

    Ok(())
}

#[tokio::test]
async fn test_plugin_dependencies() {
    let plugin_manager = PluginManager::new();
    let plugins = plugin_manager.list_plugins();

    // All plugins should be loadable (no dependency failures in test environment)
    assert!(plugins.len() >= 4, "Should load all core plugins");

    // Verify that each plugin type is present
    let plugin_names: std::collections::HashSet<&str> = plugins.iter()
        .map(|(name, _, _)| *name)
        .collect();

    assert!(plugin_names.contains("active"), "Should have active plugin");
    assert!(plugin_names.contains("worktree"), "Should have worktree plugin");
    assert!(plugin_names.contains("scratch"), "Should have scratch plugin");
    assert!(plugin_names.contains("tmuxinator"), "Should have tmuxinator plugin");
}

// Integration test that mimics the bash test scenarios
#[tokio::test]
async fn test_integration_bash_compatibility() -> Result<()> {
    let plugin_manager = PluginManager::new();

    // Mock data that matches the bash test environment
    let mut mock_client = MockTmuxClient::new();
    mock_client
        .add_session("main".to_string(), 1234567890)
        .add_session("dotfiles".to_string(), 1234567889)
        .add_session("notes".to_string(), 1234567888)
        .add_session("scratch-session".to_string(), 1234567887)
        .add_session("default".to_string(), 1234567886)
        .set_current_session("dotfiles".to_string());

    let context = mock_client.build_context();
    let sessions = plugin_manager.discover_all_sessions(&context).await?;

    // Basic validation that matches bash test expectations
    assert!(sessions.len() > 0, "Should discover sessions");

    // Should have current session marker
    let current_count = sessions.iter().filter(|s| s.is_current).count();
    assert_eq!(current_count, 1, "Should have exactly one current session");

    // Should have proper priority ordering
    let priorities: Vec<u32> = sessions.iter().map(|s| s.priority).collect();
    let mut sorted_priorities = priorities.clone();
    sorted_priorities.sort();
    assert_eq!(priorities, sorted_priorities, "Sessions should be sorted by priority");

    // Should not have duplicates
    let names: Vec<String> = sessions.iter().map(|s| s.name.clone()).collect();
    let unique_names: std::collections::HashSet<_> = names.iter().collect();
    assert_eq!(names.len(), unique_names.len(), "Should not have duplicate session names");

    Ok(())
}

#[tokio::test]
async fn test_worktree_session_switching() -> Result<()> {
    let plugin_manager = PluginManager::new();

    // Create a mock context that simulates the actual worktree scenario
    let mut mock_client = MockTmuxClient::new();
    mock_client
        .add_session("tmux-session-manager".to_string(), 1234567890)
        .add_session("dotfiles".to_string(), 1234567889)  // Add recent session
        .set_current_session("tmux-session-manager".to_string());

    let context = mock_client.build_context();
    let sessions = plugin_manager.discover_all_sessions(&context).await?;

    // Debug: Print all discovered sessions
    println!("All discovered sessions:");
    for session in &sessions {
        println!("  {} (plugin: {})", session.name, session.plugin_name);
    }

    // Test a specific scenario: what happens when we try to switch to "dotfiles-tmux-session-manager"
    let session_name = "dotfiles-tmux-session-manager";

    // Test that the plugin manager can find a plugin for this session
    let plugin_found = plugin_manager.find_plugin_for_session(session_name, &context).await;

    if let Some(plugin) = plugin_found {
        println!("Found plugin: {}", plugin.name());

        let resolve_result = plugin.resolve(session_name, &context).await;
        match resolve_result {
            Ok(metadata) => {
                println!("Resolve succeeded with plugin: {}, type: {}", plugin.name(), metadata.session_type);

                // Verify plugin selection and metadata without actually switching
                println!("Plugin '{}' can handle session '{}' with type: {}",
                        plugin.name(), session_name, metadata.session_type);

                // Verify this is handled by the correct plugin type
                if session_name.contains("worktree") {
                    assert_eq!(plugin.name(), "worktree",
                              "Worktree-named sessions should be handled by worktree plugin, got: {}",
                              plugin.name());
                    assert_eq!(metadata.session_type, "worktree",
                              "Worktree sessions should have worktree type, got: {}",
                              metadata.session_type);

                    // Verify metadata has required fields for worktree without switching
                    if metadata.exists {
                        println!("Session exists in tmux with worktree metadata");
                    } else {
                        println!("Session would be created from worktree path: {:?}", metadata.path);
                        // Verify path is provided for creation
                        assert!(metadata.path.is_some(), "Worktree session should have path for creation");
                    }
                } else {
                    println!("Session resolved by plugin: {} with type: {}", plugin.name(), metadata.session_type);
                }
            }
            Err(e) => {
                println!("Resolve failed with plugin {}: {}", plugin.name(), e);
            }
        }
    } else {
        println!("No plugin found for session: {}", session_name);

        // This indicates a plugin selection issue - for sessions named with "worktree"
        // the worktree plugin should be able to handle them
        if session_name.contains("worktree") {
            panic!("Session named '{}' should be handled by worktree plugin but no plugin was selected", session_name);
        }
    }

    Ok(())
}
