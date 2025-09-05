use anyhow::{anyhow, Result};
use libloading::{Library, Symbol};
use std::collections::HashMap;
use std::path::Path;
use std::sync::Arc;

use crate::core::session::{SessionContext, SessionItem};
use crate::plugins::{
    active::ActivePlugin,
    recent::RecentPlugin,
    worktree::WorktreePlugin,
    scratch::ScratchPlugin,
    tmuxinator::TmuxinatorPlugin,
    DynamicPlugin, PluginFactory, SessionPlugin,
};

pub struct PluginManager {
    builtin_plugins: Vec<Box<dyn SessionPlugin>>,
    dynamic_plugins: Vec<Arc<Box<dyn DynamicPlugin>>>,
    _libraries: Vec<Library>, // Keep libraries alive
}

impl PluginManager {
    pub fn new() -> Self {
        let mut builtin_plugins: Vec<Box<dyn SessionPlugin>> = Vec::new();

        // Register builtin plugins in priority order
        builtin_plugins.push(Box::new(RecentPlugin::new()));
        builtin_plugins.push(Box::new(WorktreePlugin::new()));
        builtin_plugins.push(Box::new(ActivePlugin::new()));
        builtin_plugins.push(Box::new(TmuxinatorPlugin::new()));
        builtin_plugins.push(Box::new(ScratchPlugin::new()));

        Self {
            builtin_plugins,
            dynamic_plugins: Vec::new(),
            _libraries: Vec::new(),
        }
    }

    pub async fn load_dynamic_plugins(&mut self, plugin_dir: &Path) -> Result<()> {
        if !plugin_dir.exists() {
            return Ok(());
        }

        let mut entries = tokio::fs::read_dir(plugin_dir).await?;
        let mut loaded_plugins = Vec::new();
        let mut libraries = Vec::new();

        while let Some(entry) = entries.next_entry().await? {
            let path = entry.path();

            // Check for shared library extensions
            if let Some(extension) = path.extension() {
                let ext_str = extension.to_str().unwrap_or("");
                if !matches!(ext_str, "so" | "dylib" | "dll") {
                    continue;
                }
            } else {
                continue;
            }

            match self.load_plugin_from_path(&path).await {
                Ok((plugin, lib)) => {
                    loaded_plugins.push(Arc::new(plugin));
                    libraries.push(lib);
                    println!("Loaded dynamic plugin: {}", path.display());
                }
                Err(e) => {
                    eprintln!("Failed to load plugin {}: {}", path.display(), e);
                }
            }
        }

        self.dynamic_plugins = loaded_plugins;
        self._libraries = libraries;

        Ok(())
    }

    async fn load_plugin_from_path(&self, path: &Path) -> Result<(Box<dyn DynamicPlugin>, Library)> {
        unsafe {
            let lib = Library::new(path)?;
            let factory: Symbol<PluginFactory> = lib.get(b"create_plugin")?;
            let plugin = factory();
            Ok((plugin, lib))
        }
    }

    pub async fn discover_all_sessions(&self, context: &SessionContext) -> Result<Vec<SessionItem>> {
        let mut all_sessions = Vec::new();
        let mut session_names = HashMap::new(); // For deduplication

        // Discover from builtin plugins first
        for plugin in &self.builtin_plugins {
            // Check dependencies
            if !self.check_plugin_dependencies(plugin.as_ref()).await {
                continue;
            }

            match plugin.discover(context).await {
                Ok(sessions) => {
                    for session in sessions {
                        // Deduplicate - keep higher priority (lower number)
                        if let Some(existing) = session_names.get(&session.name) {
                            if session.priority < *existing {
                                session_names.insert(session.name.clone(), session.priority);
                                // Replace the existing session
                                all_sessions.retain(|s: &SessionItem| s.name != session.name);
                                all_sessions.push(session);
                            }
                        } else {
                            session_names.insert(session.name.clone(), session.priority);
                            all_sessions.push(session);
                        }
                    }
                }
                Err(e) => {
                    eprintln!("Plugin {} discovery failed: {}", plugin.name(), e);
                }
            }
        }

        // Discover from dynamic plugins
        for plugin in &self.dynamic_plugins {
            // Check dependencies
            if !self.check_plugin_dependencies(plugin.as_ref().as_ref()).await {
                continue;
            }

            match plugin.discover(context).await {
                Ok(sessions) => {
                    for session in sessions {
                        // Deduplicate - keep higher priority (lower number)
                        if let Some(existing) = session_names.get(&session.name) {
                            if session.priority < *existing {
                                session_names.insert(session.name.clone(), session.priority);
                                // Replace the existing session
                                all_sessions.retain(|s: &SessionItem| s.name != session.name);
                                all_sessions.push(session);
                            }
                        } else {
                            session_names.insert(session.name.clone(), session.priority);
                            all_sessions.push(session);
                        }
                    }
                }
                Err(e) => {
                    eprintln!("Plugin {} discovery failed: {}", plugin.name(), e);
                }
            }
        }

        // Sort by priority, then by timestamp (most recent first)
        all_sessions.sort_by(|a, b| {
            a.priority.cmp(&b.priority)
                .then_with(|| b.timestamp.cmp(&a.timestamp))
        });

        Ok(all_sessions)
    }

    pub async fn find_plugin_for_session(&self, session_name: &str, context: &SessionContext) -> Option<&dyn SessionPlugin> {
        // Check builtin plugins first
        for plugin in &self.builtin_plugins {
            if plugin.can_handle(session_name, context).await {
                return Some(plugin.as_ref());
            }
        }

        // Check dynamic plugins
        for plugin in &self.dynamic_plugins {
            if plugin.can_handle(session_name, context).await {
                return Some(plugin.as_ref().as_ref());
            }
        }

        None
    }


    pub async fn switch_to_session(&self, session_name: &str, context: &SessionContext) -> Result<()> {
        if let Some(plugin) = self.find_plugin_for_session(session_name, context).await {
            let metadata = plugin.resolve(session_name, context).await?;
            plugin.switch(session_name, &metadata).await
        } else {
            Err(anyhow!("No plugin found for session: {}", session_name))
        }
    }

    pub async fn preview_session(&self, session_name: &str, context: &SessionContext) -> Result<String> {
        if let Some(plugin) = self.find_plugin_for_session(session_name, context).await {
            let metadata = plugin.resolve(session_name, context).await?;
            plugin.preview(session_name, &metadata).await
        } else {
            Ok(format!("No preview available for session: {}", session_name))
        }
    }

    pub async fn kill_session(&self, session_name: &str, context: &SessionContext) -> Result<()> {
        if let Some(plugin) = self.find_plugin_for_session(session_name, context).await {
            plugin.kill(session_name).await
        } else {
            Err(anyhow!("No plugin found for session: {}", session_name))
        }
    }


    pub async fn start_session(&self, session_name: &str, context: &SessionContext) -> Result<()> {
        if let Some(plugin) = self.find_plugin_for_session(session_name, context).await {
            let metadata = plugin.resolve(session_name, context).await?;
            plugin.start(session_name, &metadata).await
        } else {
            Err(anyhow!("No plugin found for session: {}", session_name))
        }
    }

    async fn check_plugin_dependencies(&self, plugin: &dyn SessionPlugin) -> bool {
        for dep in plugin.dependencies() {
            if !self.command_exists(dep).await {
                return false;
            }
        }
        true
    }

    async fn command_exists(&self, command: &str) -> bool {
        tokio::process::Command::new("which")
            .arg(command)
            .output()
            .await
            .map(|output| output.status.success())
            .unwrap_or(false)
    }

    pub fn list_plugins(&self) -> Vec<(&str, &str, u32)> {
        let mut plugins = Vec::new();

        for plugin in &self.builtin_plugins {
            plugins.push((plugin.name(), plugin.description(), plugin.priority()));
        }

        for plugin in &self.dynamic_plugins {
            plugins.push((plugin.name(), plugin.description(), plugin.priority()));
        }

        plugins.sort_by_key(|&(_, _, priority)| priority);
        plugins
    }

    pub fn get_all_help_text(&self) -> Vec<String> {
        let mut help_lines = Vec::new();

        // Collect help from all builtin plugins in priority order
        for plugin in &self.builtin_plugins {
            help_lines.extend(plugin.get_help_text());
        }

        // Collect help from dynamic plugins
        for plugin in &self.dynamic_plugins {
            help_lines.extend(plugin.get_help_text());
        }

        help_lines
    }
}