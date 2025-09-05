use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SessionItem {
    pub id: Uuid,
    pub name: String,
    pub plugin_name: String,
    pub priority: u32,
    pub timestamp: DateTime<Utc>,
    pub is_current: bool,
    pub is_active: bool,
    pub metadata: SessionMetadata,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SessionMetadata {
    pub session_type: String,
    pub path: Option<String>,
    pub exists: bool,
    pub properties: HashMap<String, String>,
}

#[derive(Debug, Clone)]
pub struct SessionContext {
    pub current_session: Option<String>,
    pub active_sessions: Vec<String>,
    pub scratch_sessions: Vec<String>,
    pub all_tmux_sessions: Vec<TmuxSession>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TmuxSession {
    pub name: String,
    pub last_attached: DateTime<Utc>,
    pub windows: u32,
    pub attached: bool,
    pub current_path: Option<String>,
}

impl SessionItem {
    pub fn new(
        name: String,
        plugin_name: String,
        priority: u32,
        metadata: SessionMetadata,
    ) -> Self {
        Self {
            id: Uuid::new_v4(),
            name,
            plugin_name,
            priority,
            timestamp: Utc::now(),
            is_current: false,
            is_active: false,
            metadata,
        }
    }

    pub fn with_current(mut self, is_current: bool) -> Self {
        self.is_current = is_current;
        self
    }

    pub fn with_active(mut self, is_active: bool) -> Self {
        self.is_active = is_active;
        self
    }

    pub fn with_timestamp(mut self, timestamp: DateTime<Utc>) -> Self {
        self.timestamp = timestamp;
        self
    }

    pub fn format_for_display(&self) -> String {
        let icon = self.get_display_icon();
        let color = self.get_display_color();
        let suffix = self.get_display_suffix();

        format!("{}{}\x1b[0m {}{}", color, icon, self.name, suffix)
    }

    fn get_display_icon(&self) -> &str {
        if self.is_current {
            "→"
        } else {
            match self.plugin_name.as_str() {
                "recent" => "★",
                "active" => "●",
                "worktree" => if self.is_active { "●" } else { "○" },
                "scratch" => "󱗽",
                "tmuxinator" => "●",
                _ => "●",
            }
        }
    }

    fn get_display_color(&self) -> &str {
        match self.plugin_name.as_str() {
            "recent" => "\x1b[1;33m", // YELLOW (like the bash version)
            "active" => "\x1b[1;32m", // GREEN
            "worktree" => "\x1b[0;34m", // BLUE
            "scratch" => if self.is_active { "\x1b[1;32m" } else { "\x1b[0;34m" }, // GREEN if active, BLUE if not
            "tmuxinator" => "\x1b[0;90m", // DARK_GREY
            _ => "\x1b[1;32m", // Default GREEN
        }
    }

    fn get_display_suffix(&self) -> String {
        // Show plugin name for all plugins except recent, active, and scratch
        if !["recent", "active", "scratch"].contains(&self.plugin_name.as_str()) {
            format!(" ({})", self.plugin_name)
        } else {
            String::new()
        }
    }
}

impl SessionMetadata {
    pub fn new(session_type: String) -> Self {
        Self {
            session_type,
            path: None,
            exists: false,
            properties: HashMap::new(),
        }
    }

    pub fn with_path(mut self, path: String) -> Self {
        self.path = Some(path);
        self
    }

    pub fn with_exists(mut self, exists: bool) -> Self {
        self.exists = exists;
        self
    }

    pub fn with_property(mut self, key: String, value: String) -> Self {
        self.properties.insert(key, value);
        self
    }

    pub fn get_property(&self, key: &str) -> Option<&String> {
        self.properties.get(key)
    }
}

impl SessionContext {
    pub fn new() -> Self {
        Self {
            current_session: None,
            active_sessions: Vec::new(),
            scratch_sessions: Vec::new(),
            all_tmux_sessions: Vec::new(),
        }
    }

    pub fn with_current_session(mut self, session: Option<String>) -> Self {
        self.current_session = session;
        self
    }

    pub fn with_active_sessions(mut self, sessions: Vec<String>) -> Self {
        self.active_sessions = sessions;
        self
    }

    pub fn with_scratch_sessions(mut self, sessions: Vec<String>) -> Self {
        self.scratch_sessions = sessions;
        self
    }

    pub fn with_all_tmux_sessions(mut self, sessions: Vec<TmuxSession>) -> Self {
        self.all_tmux_sessions = sessions;
        self
    }
}