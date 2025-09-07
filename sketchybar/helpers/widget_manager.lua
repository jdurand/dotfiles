local Screen = require("helpers.screen")

local WidgetManager = {}

-- Widget visibility configuration
local WIDGET_CONFIG = {
  {
    name = "wifi",
    threshold = 1600,
    items = {"widgets.wifi1", "widgets.wifi2", "widgets.wifi.padding"},
    priority = 1
  },
  {
    name = "volume",
    threshold = 1500,
    items = {"widgets.volume1", "widgets.volume2", "widgets.volume.padding"},
    priority = 2
  },
  {
    name = "battery",
    threshold = 1400,
    items = {"widgets.battery", "widgets.battery.padding"},
    priority = 3
  }
  -- CPU is never hidden as per requirements
}

-- Manage widget visibility based on available screen space
function WidgetManager.update_visibility()
  local screen_props = Screen.get_properties()
  local screen_width = screen_props.width

  Logger:info('Managing widget visibility for screen width: ' .. screen_width)

  for _, widget in ipairs(WIDGET_CONFIG) do
    local should_hide = screen_width <= widget.threshold

    if should_hide then
      Logger:info('Hiding ' .. widget.name .. ' widgets due to screen constraints')
      for _, item in ipairs(widget.items) do
        SketchyBar.set(item, { drawing = false })
      end
    else
      Logger:debug('Showing ' .. widget.name .. ' widgets')
      for _, item in ipairs(widget.items) do
        SketchyBar.set(item, { drawing = true })
      end
    end
  end
end

-- Initialize widget visibility management
function WidgetManager.init()
  Logger:info('Initializing widget visibility management')
  WidgetManager.update_visibility()
end

-- Event handler for screen changes
function WidgetManager.on_screen_change()
  Logger:info('Screen change detected, updating widget visibility')
  WidgetManager.update_visibility()
end

return WidgetManager