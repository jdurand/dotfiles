-- Timer Helper Module
-- Provides reusable timer management with automatic sleep/wake handling

-- Configuration
local SKETCHYBAR_EXECUTABLE = "/opt/homebrew/bin/sketchybar"

local Timer = {}

-- Create a managed timer that automatically handles sleep/wake events
-- @param config Table with:
--   - name: Event name to trigger (required)
--   - interval: Interval in seconds (required)
--   - item: SketchyBar item to subscribe to system_woke (required)
--   - on_wake: Optional callback to run when system wakes
function Timer.create(config)
  if not config.name or not config.interval or not config.item then
    Logger:error("Timer.create requires name, interval, and item")
    return
  end

  local timer = {
    name = config.name,
    interval = config.interval,
    item = config.item,
    on_wake = config.on_wake
  }

  -- Register the event
  SketchyBar.add("event", timer.name)

  -- Start the timer
  local function start_timer()
    local cmd = string.format(
      "while true; do sleep %d; %s --trigger %s; done &",
      timer.interval,
      SKETCHYBAR_EXECUTABLE,
      timer.name
    )
    SketchyBar.exec(cmd)
  end

  -- Kill existing timer processes for this event
  local function kill_timer()
    SketchyBar.exec(string.format("pkill -f 'sketchybar --trigger %s' 2>/dev/null", timer.name))
  end

  -- Restart timer (kill old, start new)
  local function restart_timer()
    kill_timer()
    start_timer()
  end

  -- Kill any existing timer process for this event before starting
  -- This is important when sketchybar reloads to prevent duplicate processes
  kill_timer()

  -- Add small delay to ensure processes are killed before starting new ones
  SketchyBar.exec("sleep 0.1", function()
    -- Initial start
    start_timer()
  end)

  -- Subscribe to system wake event
  timer.item:subscribe("system_woke", function()
    -- Kill existing timer process
    kill_timer()

    -- Wait for system to stabilize
    SketchyBar.exec("sleep 2", function()
      -- Restart timer
      start_timer()

      -- Run optional wake callback
      if timer.on_wake then
        timer.on_wake()
      end
    end)
  end)

  -- Return control functions
  return {
    restart = restart_timer,
    kill = kill_timer
  }
end

-- Create multiple timers at once with shared wake handling
-- @param config Table with:
--   - item: SketchyBar item to subscribe to system_woke (required)
--   - timers: Array of timer configs, each with name and interval (required)
--   - on_wake: Optional callback to run when system wakes
function Timer.create_group(config)
  if not config.item or not config.timers then
    Logger:error("Timer.create_group requires item and timers array")
    return
  end

  local timers = {}

  -- First, kill any existing timer processes for these events
  for _, timer_config in ipairs(config.timers) do
    SketchyBar.exec(string.format("pkill -f 'sketchybar --trigger %s' 2>/dev/null", timer_config.name))
    table.insert(timers, timer_config)
  end

  -- Add small delay to ensure processes are killed before starting new ones
  SketchyBar.exec("sleep 0.1", function()
    -- Register all events and start timers
    for _, timer_config in ipairs(config.timers) do
      SketchyBar.add("event", timer_config.name)

      local cmd = string.format(
        "while true; do sleep %d; %s --trigger %s; done &",
        timer_config.interval,
        SKETCHYBAR_EXECUTABLE,
        timer_config.name
      )
      SketchyBar.exec(cmd)
    end
  end)

  -- Kill all timer processes
  local function kill_all()
    for _, timer in ipairs(timers) do
      SketchyBar.exec(string.format("pkill -f 'sketchybar --trigger %s' 2>/dev/null", timer.name))
    end
  end

  -- Restart all timers
  local function restart_all()
    kill_all()
    for _, timer in ipairs(timers) do
      local cmd = string.format(
        "while true; do sleep %d; %s --trigger %s; done &",
        timer.interval,
        SKETCHYBAR_EXECUTABLE,
        timer.name
      )
      SketchyBar.exec(cmd)
    end
  end

  -- Subscribe to system wake event once for all timers
  config.item:subscribe("system_woke", function()
    -- Kill all existing timer processes
    kill_all()

    -- Wait for system to stabilize
    SketchyBar.exec("sleep 2", function()
      -- Restart all timers
      for _, timer in ipairs(timers) do
        local cmd = string.format(
          "while true; do sleep %d; %s --trigger %s; done &",
          timer.interval,
          SKETCHYBAR_EXECUTABLE,
          timer.name
        )
        SketchyBar.exec(cmd)
      end

      -- Run optional wake callback
      if config.on_wake then
        config.on_wake()
      end
    end)
  end)

  -- Return control functions
  return {
    restart = restart_all,
    kill = kill_all
  }
end

return Timer
