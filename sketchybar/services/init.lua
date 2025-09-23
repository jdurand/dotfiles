-- Services initialization
-- This file initializes all core services after widgets are loaded

local WidgetManager = require("helpers.widget_manager")

-- Initialize widget visibility management
WidgetManager.init()

-- Start volume event provider
SketchyBar.add("event", "volume_change")
local volume_cmd = string.format(
  "while true; do " ..
  "volume=$(osascript -e 'output volume of (get volume settings)' 2>/dev/null); " ..
  "if [ \"$volume\" != \"missing value\" ] && [ ! -z \"$volume\" ]; then " ..
  "/opt/homebrew/bin/sketchybar --trigger volume_change INFO=$volume; " ..
  "fi; " ..
  "sleep 2; " ..
  "done &"
)
SketchyBar.exec(volume_cmd)

Logger:info('All services initialized')
