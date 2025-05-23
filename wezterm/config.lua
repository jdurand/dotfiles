-- Pull in the wezterm API
local wezterm = require 'wezterm'

-- This will hold the configuration.
local config = wezterm.config_builder()

-- This is where you actually apply your config choices

config.hide_tab_bar_if_only_one_tab = true
config.disable_default_key_bindings = true
config.window_close_confirmation = 'NeverPrompt'

-- hide the top bar on macOS
if string.match(wezterm.target_triple, 'darwin') then
  config.window_decorations = 'RESIZE'
else
  config.window_decorations = 'TITLE | RESIZE'
end

-- apply color scheme according to the time of day
local hour = os.date("*t").hour

config.color_scheme = (hour >= 6 and hour < 18) and 'Tokyo Night Moon' or 'Tokyo Night'

config.window_background_opacity = 0.8
config.macos_window_background_blur = 10
config.font = wezterm.font('VictorMono Nerd Font Mono', { weight = 'DemiBold' })
config.font_size = 15.0

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

  -- close application
  { key = 'q', mods = 'CMD', action = wezterm.action.QuitApplication },

  -- toggle fullscreen
  { key = 'F11', action = wezterm.action.ToggleFullScreen },

  -- This workaround remaps Ctrl+i to Ctrl+a in Tmux to prevent it from being
  -- interpreted as TAB, enabling proper handling in child programs, like Neovim.
  { key = 'i', mods = 'CTRL', action = wezterm.action.SendString('\x1bi') },

  -- zoom in (increase font size)
  { key = '=', mods = 'SUPER', action = wezterm.action.IncreaseFontSize },
  -- zoom out (decrease font size)
  { key = '-', mods = 'SUPER', action = wezterm.action.DecreaseFontSize },
  -- reset font size
  { key = '0', mods = 'SUPER', action = wezterm.action.ResetFontSize },
}

-- config.inactive_pane_hsb = {
--   saturation = 1.0,
--   brightness = 1.0,
-- }

-- and finally, return the configuration to wezterm
return config
