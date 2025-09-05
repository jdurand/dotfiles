use anyhow::Result;
use async_trait::async_trait;
use serde::{Deserialize, Serialize};

use crate::core::session::{SessionContext, SessionItem, SessionMetadata};

#[async_trait]
pub trait SessionPlugin: Send + Sync {
    /// Plugin metadata
    fn name(&self) -> &str;
    fn description(&self) -> &str;
    fn priority(&self) -> u32;
    fn dependencies(&self) -> Vec<&str> { Vec::new() }

    /// Discover sessions that this plugin can manage
    async fn discover(&self, context: &SessionContext) -> Result<Vec<SessionItem>>;

    /// Resolve metadata for a specific session
    async fn resolve(&self, session_name: &str, context: &SessionContext) -> Result<SessionMetadata>;

    /// Switch to a session (create if necessary)
    async fn switch(&self, session_name: &str, metadata: &SessionMetadata) -> Result<()>;

    /// Generate preview content for a session
    async fn preview(&self, session_name: &str, metadata: &SessionMetadata) -> Result<String> {
        Ok(format!("Session: {}\nType: {}", session_name, metadata.session_type))
    }

    /// Kill a session
    async fn kill(&self, session_name: &str) -> Result<()> {
        // Default implementation - can be overridden
        use crate::core::tmux::TmuxClient;
        let tmux = TmuxClient::new();
        tmux.kill_session(session_name).await
    }


    /// Start a session in background (for tmuxinator-like plugins)
    async fn start(&self, session_name: &str, metadata: &SessionMetadata) -> Result<()> {
        // Default implementation - just switch
        self.switch(session_name, metadata).await
    }

    /// Get help text for this plugin's session types
    fn get_help_text(&self) -> Vec<String> {
        Vec::new() // Default: no plugin-specific help
    }

    /// Check if this plugin can handle a specific session
    async fn can_handle(&self, session_name: &str, context: &SessionContext) -> bool {
        self.resolve(session_name, context).await.is_ok()
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PluginMetadata {
    pub name: String,
    pub description: String,
    pub version: String,
    pub priority: u32,
    pub dependencies: Vec<String>,
    pub author: Option<String>,
    pub homepage: Option<String>,
}

/// Trait for dynamic plugins loaded from shared libraries
pub trait DynamicPlugin: SessionPlugin {}

/// Plugin factory function signature for dynamic loading
pub type PluginFactory = fn() -> Box<dyn DynamicPlugin>;

/// Macro to simplify plugin registration for dynamic plugins
#[macro_export]
macro_rules! register_plugin {
    ($plugin_type:ty) => {
        #[no_mangle]
        pub fn create_plugin() -> Box<dyn $crate::plugins::DynamicPlugin> {
            Box::new(<$plugin_type>::new())
        }
    };
}