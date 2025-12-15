-- Optimized SketchyBar Initialization
-- Uses startup helper for better performance and recovery

-- Core modules
SketchyBar = require("sketchybar")
Logger = require("logger")

-- Load startup optimization helper
local Startup = require("helpers.startup")

-- Set the bar name (if using non-default)
-- SketchyBar.set_bar_name("bottom_bar")

-- Small initial delay to let SketchyBar stabilize
SketchyBar.exec("sleep 0.2", function()
  Logger:info("Starting SketchyBar initialization")
end)

-- Clean up any orphaned processes from previous instances
Startup.cleanup_processes()

-- Bundle the initial configuration
SketchyBar.begin_config()
require("bar")
require("default")
SketchyBar.end_config()

-- Load essential items with minimal delay
SketchyBar.exec("sleep 0.3", function()
  require("items.left")
  require("items.right.calendar")
end)

-- Load critical system widgets with minimal delay
SketchyBar.exec("sleep 0.5", function()
  require("items.right.widgets.volume")
  require("items.right.widgets.battery")
  require("items.right.widgets.wifi")
  require("items.right.widgets.cpu")
end)

-- Register delayed initialization for service widgets
-- These make external API calls so we delay them to improve startup
Startup.delayed_init("docker", function()
  require("items.right.widgets.docker_containers")
end, 1)

Startup.delayed_init("pr_reviews", function()
  require("items.right.widgets.pr_reviews")
end, 2)

Startup.delayed_init("jira_issues", function()
  require("items.right.widgets.jira_issues")
end, 3)

Startup.delayed_init("calendar_meetings", function()
  require("items.right.widgets.calendar_meetings")
end, 4)

Startup.delayed_init("spotify", function()
  require("items.right.widgets.spotify")
end, 5)

-- Execute staged initialization
Startup.execute_pending()

-- Set up watchdog for hang detection
Startup.setup_watchdog()

-- Initialize services after items are loaded
SketchyBar.exec("sleep 2", function()
  require("services")
  Logger:info("Services initialized")

  -- Set up global wake handler for timers
  local Timer = require("helpers.timer")
  Timer.setup_global_wake_handler()
  Logger:info("Services and timer manager initialized")
end)

-- Set up global wake and display change handlers
local system_handler = SketchyBar.add("item", "system.event_handler", {
  drawing = false,
})

system_handler:subscribe("system_woke", function()
  Logger:info("System wake detected - global handler")
  Startup.handle_system_wake()
end)

system_handler:subscribe("display_change", function()
  Logger:info("Display change detected - global handler")
  Startup.handle_display_change()
end)

-- Perform initial health check
SketchyBar.exec("sleep 5", function()
  Startup.health_check()
end)

-- Run the event loop
SketchyBar.event_loop()