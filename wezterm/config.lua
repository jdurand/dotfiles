-- Pull in the wezterm API
local wezterm = require 'wezterm'

-- This will hold the configuration.
local config = wezterm.config_builder()

-- This is where you actually apply your config choices

config.hide_tab_bar_if_only_one_tab = true
config.disable_default_key_bindings = true
config.window_close_confirmation = 'NeverPrompt'

-- config.window_decorations = 'RESIZE'
-- config.window_decorations = 'NONE'
-- config.window_decorations = 'TITLE'
config.window_decorations = 'TITLE | RESIZE'

local hour = os.date("*t").hour

config.color_scheme = (hour >= 6 and hour < 18) and 'Tokyo Night Moon' or 'Tokyo Night'

config.window_background_opacity = 0.8
config.macos_window_background_blur = 10
config.font = wezterm.font 'VictorMono Nerd Font Mono'
config.font_size = 14.0

config.window_padding = {
  bottom = 0,
}

config.colors = {
  -- foreground = 'silver',
  -- background = 'black',

  cursor_bg = 'white',
  -- Overrides the text color when the current cell is occupied by the cursor
  cursor_fg = 'black',
  -- Specifies the border color of the cursor when the cursor style is set to Block,
  -- or the color of the vertical or horizontal bar when the cursor style is set to
  -- Bar or Underline.
  cursor_border = 'white',
}

config.keys = {
  -- paste from the clipboard
  { key = 'v', mods = 'SUPER', action = wezterm.action.PasteFrom 'Clipboard' },
  { key = 'v', mods = 'CTRL|SHIFT', action = wezterm.action.PasteFrom 'Clipboard' },

  -- paste from the primary selection
  { key = 'V', mods = 'SUPER', action = wezterm.action.PasteFrom 'PrimarySelection' },
  { key = 'V', mods = 'CTRL|SHIFT', action = wezterm.action.PasteFrom 'PrimarySelection' },

  -- close tab with
  { key = 'w', mods = 'CMD', action = wezterm.action.CloseCurrentTab { confirm = false } },

  -- close pane
  { key = 'W', mods = 'CMD', action = wezterm.action.CloseCurrentPane { confirm = false } },

  -- toggle fullscreen
  { key = 'F11', action = wezterm.action.ToggleFullScreen },
}

-- config.inactive_pane_hsb = {
--   saturation = 1.0,
--   brightness = 1.0,
-- }

-- and finally, return the configuration to wezterm
return config
