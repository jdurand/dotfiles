use anyhow::Result;
use serde::{Deserialize, Serialize};
use std::path::PathBuf;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Config {
    pub preview_enabled: bool,
    pub plugin_dir: Option<PathBuf>,
    pub tmux_socket: Option<String>,
    pub ui_settings: UiSettings,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UiSettings {
    pub popup_width: String,
    pub popup_height: String,
    pub preview_position: String,
    pub show_plugin_names: bool,
}

impl Default for Config {
    fn default() -> Self {
        Self {
            preview_enabled: true,
            plugin_dir: None, // Will use default ~/.config/tmux-session-manager/plugins
            tmux_socket: None,
            ui_settings: UiSettings::default(),
        }
    }
}

impl Default for UiSettings {
    fn default() -> Self {
        Self {
            popup_width: "60%".to_string(),
            popup_height: "40%".to_string(),
            preview_position: "right:50%:wrap".to_string(),
            show_plugin_names: false,
        }
    }
}

impl Config {
    pub async fn load() -> Result<Self> {
        let config_path = Self::get_config_path()?;

        if config_path.exists() {
            let content = tokio::fs::read_to_string(&config_path).await?;
            let config: Config = serde_json::from_str(&content)?;
            Ok(config)
        } else {
            Ok(Self::default())
        }
    }

    pub async fn save(&self) -> Result<()> {
        let config_path = Self::get_config_path()?;

        if let Some(parent) = config_path.parent() {
            tokio::fs::create_dir_all(parent).await?;
        }

        let content = serde_json::to_string_pretty(self)?;
        tokio::fs::write(&config_path, content).await?;

        Ok(())
    }

    pub fn get_config_path() -> Result<PathBuf> {
        let config_dir = dirs::config_dir()
            .ok_or_else(|| anyhow::anyhow!("Could not find config directory"))?;

        Ok(config_dir.join("tmux-session-manager").join("config.json"))
    }

    pub fn get_plugin_dir(&self) -> PathBuf {
        if let Some(ref custom_dir) = self.plugin_dir {
            custom_dir.clone()
        } else {
            dirs::config_dir()
                .unwrap_or_else(|| std::env::current_dir().unwrap_or_default())
                .join("tmux-session-manager")
                .join("plugins")
        }
    }

    pub async fn toggle_preview(&mut self) -> Result<()> {
        self.preview_enabled = !self.preview_enabled;
        self.save().await
    }

}