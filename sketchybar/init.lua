-- Optimized SketchyBar Initialization
-- Uses startup helper for better performance and recovery

-- Core modules
SketchyBar = require("sketchybar")
Logger = require("logger")

-- Load startup optimization helper
local Startup = require("helpers.startup")

-- Set the bar name (if using non-default)
-- SketchyBar.set_bar_name("bottom_bar")

-- Clean up any orphaned processes from previous instances
Startup.cleanup_processes()

-- Bundle the initial configuration
SketchyBar.begin_config()
require("bar")
require("default")
SketchyBar.end_config()

-- Load essential items immediately (no delay)
require("items.left")
require("items.right.calendar")

-- Load critical system widgets immediately
require("items.right.widgets.volume")
require("items.right.widgets.battery")
require("items.right.widgets.wifi")
require("items.right.widgets.cpu")

-- Low priority items (7-10): External service widgets
Startup.delayed_init("docker", function()
  require("items.right.widgets.docker_containers")
end, 7)

Startup.delayed_init("dev_widgets", function()
  require("items.right.widgets.pr_reviews")
  require("items.right.widgets.jira_issues")
end, 8)

Startup.delayed_init("calendar_meetings", function()
  require("items.right.widgets.calendar_meetings")
end, 9)

-- Execute staged initialization
Startup.execute_pending()

-- Set up watchdog for hang detection
Startup.setup_watchdog()

-- Initialize services after items are loaded
SketchyBar.exec("sleep 2", function()
  require("services")
  Logger:info("Services initialized")

  -- Timers are initialized automatically by each widget
  Logger:info("Services and widgets initialized")
end)

-- Set up global wake handler
local wake_handler = SketchyBar.add("item", "system.global_wake", {
  drawing = false,
})

wake_handler:subscribe("system_woke", function()
  Logger:info("System wake detected - global handler")
  Startup.handle_system_wake()
end)

-- Perform initial health check
SketchyBar.exec("sleep 5", function()
  Startup.health_check()
end)

-- Run the event loop
SketchyBar.event_loop()