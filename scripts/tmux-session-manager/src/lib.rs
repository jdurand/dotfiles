pub mod core;
pub mod plugins;
pub mod config;

// Re-export commonly used items for testing
pub use core::session::{SessionContext, SessionItem, SessionMetadata, TmuxSession};
pub use core::tmux::TmuxClient;
pub use plugins::{PluginManager, SessionPlugin};
pub use config::Config;