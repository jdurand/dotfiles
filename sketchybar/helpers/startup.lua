-- Startup Helper Module
-- Provides optimized startup and recovery mechanisms for SketchyBar

local Logger = require("logger")

local Startup = {}

-- Configuration
local CONFIG = {
  STARTUP_DELAY = 1.0, -- Initial delay before starting heavy operations
  STAGGER_DELAY = 0.2, -- Delay between starting each widget
  MAX_RETRIES = 3,     -- Maximum retries for failed operations
  RETRY_DELAY = 2,     -- Delay between retries
}

-- Track initialization state
local initialized_widgets = {}
local pending_inits = {}

-- Delayed initialization wrapper
-- Staggers widget initialization to prevent startup bottlenecks
function Startup.delayed_init(widget_name, init_function, priority)
  priority = priority or 5 -- Default priority (1=highest, 10=lowest)

  table.insert(pending_inits, {
    name = widget_name,
    init = init_function,
    priority = priority,
    retries = 0
  })
end

-- Execute pending initializations in priority order
function Startup.execute_pending()
  -- Sort by priority
  table.sort(pending_inits, function(a, b)
    return a.priority < b.priority
  end)

  local function init_next(index)
    if index > #pending_inits then
      Logger:info("All widgets initialized successfully")
      return
    end

    local widget = pending_inits[index]

    -- Skip if already initialized
    if initialized_widgets[widget.name] then
      init_next(index + 1)
      return
    end

    Logger:info("Initializing " .. widget.name)

    -- Wrap initialization in protected call
    local success, err = pcall(widget.init)

    if success then
      initialized_widgets[widget.name] = true
      -- Stagger next initialization
      SketchyBar.exec("sleep " .. CONFIG.STAGGER_DELAY, function()
        init_next(index + 1)
      end)
    else
      Logger:error("Failed to initialize " .. widget.name .. ": " .. tostring(err))

      -- Retry logic
      if widget.retries < CONFIG.MAX_RETRIES then
        widget.retries = widget.retries + 1
        Logger:info("Retrying " .. widget.name .. " (attempt " .. widget.retries .. ")")

        SketchyBar.exec("sleep " .. CONFIG.RETRY_DELAY, function()
          init_next(index) -- Retry same widget
        end)
      else
        Logger:error("Max retries reached for " .. widget.name .. ", skipping")
        init_next(index + 1)
      end
    end
  end

  -- Start initialization after startup delay
  SketchyBar.exec("sleep " .. CONFIG.STARTUP_DELAY, function()
    init_next(1)
  end)
end

-- Clean up orphaned processes from previous SketchyBar instances
function Startup.cleanup_processes()
  Logger:info("Cleaning up orphaned processes")

  -- Kill orphaned timer processes
  SketchyBar.exec("pkill -f 'sketchybar --trigger' 2>/dev/null || true")

  -- Kill orphaned event providers
  SketchyBar.exec("pkill -f 'cpu_load|gpu_load' 2>/dev/null || true")

  -- Small delay to ensure cleanup completes
  SketchyBar.exec("sleep 0.5")
end

-- Recovery mechanism for hangs
function Startup.setup_watchdog()
  -- Create a watchdog that monitors SketchyBar responsiveness
  local watchdog_interval = 60 -- Check every minute

  SketchyBar.add("event", "watchdog_check")

  local watchdog_cmd = string.format(
    "while true; do sleep %d; /opt/homebrew/bin/sketchybar --trigger watchdog_check; done &",
    watchdog_interval
  )

  SketchyBar.exec(watchdog_cmd)

  -- Create a hidden item to handle watchdog events
  local watchdog = SketchyBar.add("item", "system.watchdog", {
    drawing = false,
  })

  local last_check = os.time()

  watchdog:subscribe("watchdog_check", function()
    local current_time = os.time()
    local time_diff = current_time - last_check

    -- If more than 2x the interval has passed, we likely recovered from a hang/sleep
    if time_diff > (watchdog_interval * 2) then
      Logger:warn("Detected potential hang/sleep recovery, refreshing widgets")

      -- Trigger refresh of time-sensitive widgets
      SketchyBar.exec("/opt/homebrew/bin/sketchybar --trigger force_refresh")
    end

    last_check = current_time
  end)
end

-- System wake handler with improved recovery
function Startup.handle_system_wake()
  Logger:info("System wake detected, initiating recovery")

  -- Kill and restart all timer processes
  Startup.cleanup_processes()

  -- Wait for system to stabilize
  SketchyBar.exec("sleep 3", function()
    -- Trigger refresh of all widgets
    SketchyBar.exec("/opt/homebrew/bin/sketchybar --trigger force_refresh")

    -- Re-initialize failed widgets if any
    for name, _ in pairs(pending_inits) do
      if not initialized_widgets[name] then
        Logger:info("Re-initializing " .. name .. " after wake")
        Startup.delayed_init(name, pending_inits[name].init, 1)
      end
    end

    Startup.execute_pending()
  end)
end

-- Check system health and attempt recovery if needed
function Startup.health_check()
  -- Check if SketchyBar is responsive
  SketchyBar.exec("echo 'health_check'", function(result)
    if result and result:match("health_check") then
      Logger:info("SketchyBar is responsive")
    else
      Logger:error("SketchyBar may be unresponsive, attempting recovery")

      -- Force reload configuration
      SketchyBar.exec("/opt/homebrew/bin/sketchybar --reload")
    end
  end)
end

return Startup
