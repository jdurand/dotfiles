-- Services initialization
-- This file initializes all core services after widgets are loaded

local WidgetManager = require("helpers.widget_manager")

-- Initialize widget visibility management
WidgetManager.init()

Logger:info('All services initialized')
