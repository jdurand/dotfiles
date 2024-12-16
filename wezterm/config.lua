-- Pull in the wezterm API
local wezterm = require 'wezterm'

-- This will hold the configuration.
local config = wezterm.config_builder()

-- This is where you actually apply your config choices

config.hide_tab_bar_if_only_one_tab = true
config.window_decorations = 'RESIZE'
config.window_close_confirmation = 'NeverPrompt'

local hour = os.date("*t").hour

if hour >= 6 and hour < 18 then
  config.color_scheme = 'Catppuccin Mocha'
  config.window_background_opacity = 0.9
else
  config.color_scheme = 'Synth Midnight'
  config.window_background_opacity = 0.85
end

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

-- config.inactive_pane_hsb = {
--   saturation = 1.0,
--   brightness = 1.0,
-- }

-- and finally, return the configuration to wezterm
return config
