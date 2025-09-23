-- Timer V2 Helper Module
-- Improved timer management with better sleep/wake handling and process management
-- Uses a single background process to manage all timers, reducing overhead

local Logger = require("logger")

-- Configuration
local SKETCHYBAR_EXECUTABLE = "/opt/homebrew/bin/sketchybar"
local TIMER_MANAGER_SCRIPT = os.getenv("TMPDIR") .. "sketchybar_timer_manager.sh"

local Timer = {}

-- Track all registered timers
local registered_timers = {}
local manager_pid = nil

-- Generate the timer manager script
local function generate_manager_script()
  -- Build timer arguments for the script
  local timer_args = {}
  for name, config in pairs(registered_timers) do
    table.insert(timer_args, string.format('"%s" "%d"', name, config.interval))
  end

  -- Create the bash script using a Lua multi-line string
  -- Using arrays instead of associative arrays for compatibility
  local script_content = string.format([=[#!/bin/bash
# SketchyBar Timer Manager
# Manages all timers in a single process to reduce overhead

SKETCHYBAR_BIN="%s"

# Arrays to store timer data
timer_names=()
timer_intervals=()
timer_last_run=()

# Get current time for initialization
current_time=$(date +%%s)

# Parse timer configuration from arguments
while [[ $# -gt 0 ]]; do
  timer_names+=("$1")
  timer_intervals+=("$2")
  timer_last_run+=($current_time)
  shift 2
done

# Signal handlers
cleanup() {
  echo "Timer manager shutting down"
  exit 0
}

trap cleanup SIGTERM SIGINT

echo "Timer manager started with ${#timer_names[@]} timers"
echo "Timers: ${timer_names[@]}"

# Main loop
while true; do
  current_time=$(date +%%s)

  for i in "${!timer_names[@]}"; do
    name="${timer_names[$i]}"
    interval="${timer_intervals[$i]}"
    last="${timer_last_run[$i]}"
    elapsed=$((current_time - last))

    if [ $elapsed -ge $interval ]; then
      # Trigger the timer event
      echo "Triggering $name (elapsed: $elapsed, interval: $interval)"
      "$SKETCHYBAR_BIN" --trigger "$name" 2>&1
      timer_last_run[$i]=$current_time
    fi
  done

  # Sleep for a short interval to check timers
  sleep 1
done
]=], SKETCHYBAR_EXECUTABLE)

  -- Write the script
  local file = io.open(TIMER_MANAGER_SCRIPT, "w")
  if file then
    file:write(script_content)
    file:close()

    -- Make executable
    os.execute("chmod +x " .. TIMER_MANAGER_SCRIPT)
    return true
  end
  return false
end

-- Start the timer manager process
local function start_manager()
  if manager_pid then
    Logger:info("Timer manager already running with PID: " .. manager_pid)
    return
  end

  -- Generate the manager script
  if not generate_manager_script() then
    Logger:error("Failed to generate timer manager script")
    return
  end

  -- Build command with all registered timers
  local args = {}
  for name, config in pairs(registered_timers) do
    table.insert(args, string.format('"%s" "%d"', name, config.interval))
  end

  if #args == 0 then
    Logger:info("No timers to manage")
    return
  end

  local cmd = TIMER_MANAGER_SCRIPT .. " " .. table.concat(args, " ") .. " > /tmp/timer_manager.log 2>&1 & echo $!"

  -- Start the manager and capture its PID
  SketchyBar.exec(cmd, function(pid_str)
    manager_pid = tonumber(pid_str)
    if manager_pid then
      Logger:info("Timer manager started with PID: " .. manager_pid)
    else
      Logger:error("Failed to start timer manager")
    end
  end)
end

-- Stop the timer manager process
local function stop_manager()
  if manager_pid then
    SketchyBar.exec("kill " .. manager_pid .. " 2>/dev/null")
    Logger:info("Timer manager stopped")
    manager_pid = nil
  end

  -- Also kill any orphaned timer manager processes
  SketchyBar.exec("pkill -f sketchybar_timer_manager.sh 2>/dev/null")
end

-- Restart the timer manager
local function restart_manager()
  stop_manager()

  -- Small delay to ensure process is killed
  SketchyBar.exec("sleep 0.5", function()
    start_manager()
  end)
end

-- Create a managed timer
function Timer.create(config)
  if not config.name or not config.interval or not config.item then
    Logger:error("Timer.create requires name, interval, and item")
    return
  end

  -- Register the timer
  registered_timers[config.name] = {
    interval = config.interval,
    item = config.item,
    on_wake = config.on_wake
  }

  -- Register the event with SketchyBar
  SketchyBar.add("event", config.name)

  -- Subscribe item to wake events if on_wake callback provided
  if config.on_wake then
    config.item:subscribe("system_woke", function()
      Logger:info("System wake detected for timer: " .. config.name)

      -- Execute wake callback after a delay
      SketchyBar.exec("sleep 2", function()
        config.on_wake()
      end)
    end)
  end

  Logger:info("Timer registered: " .. config.name .. " (interval: " .. config.interval .. "s)")

  -- Restart the timer manager to include the new timer
  -- Small delay to allow multiple timers to register in quick succession
  SketchyBar.exec("sleep 0.1", function()
    restart_manager()
  end)

  -- Return control functions
  return {
    restart = restart_manager,
    kill = stop_manager
  }
end

-- Create multiple timers at once
function Timer.create_group(config)
  if not config.item or not config.timers then
    Logger:error("Timer.create_group requires item and timers array")
    return
  end

  -- Register all timers
  for _, timer_config in ipairs(config.timers) do
    registered_timers[timer_config.name] = {
      interval = timer_config.interval,
      item = config.item,
      on_wake = nil
    }

    -- Register the event with SketchyBar
    SketchyBar.add("event", timer_config.name)

    Logger:info("Timer registered: " .. timer_config.name .. " (interval: " .. timer_config.interval .. "s)")
  end

  -- Subscribe to system wake event once for the group
  config.item:subscribe("system_woke", function()
    Logger:info("System wake detected for timer group")

    -- Restart the manager after a delay
    SketchyBar.exec("sleep 2", function()
      restart_manager()

      -- Execute group wake callback if provided
      if config.on_wake then
        config.on_wake()
      end
    end)
  end)

  -- Restart the timer manager to include the new timers
  restart_manager()

  -- Return control functions
  return {
    start = function() restart_manager() end,
    stop = function() stop_manager() end
  }
end

-- Initialize all registered timers
function Timer.init_all()
  -- Stop any existing manager
  stop_manager()

  -- Wait a bit then start fresh
  SketchyBar.exec("sleep 1", function()
    start_manager()
  end)
end

-- Clean up on SketchyBar reload
function Timer.cleanup()
  stop_manager()

  -- Remove the manager script
  os.remove(TIMER_MANAGER_SCRIPT)
end

-- Global system wake handler
function Timer.setup_global_wake_handler()
  -- Create a hidden item for global wake handling
  local wake_handler = SketchyBar.add("item", "system.wake_handler", {
    drawing = false,
  })

  wake_handler:subscribe("system_woke", function()
    Logger:info("Global system wake detected, restarting timer manager")

    -- Restart the timer manager
    restart_manager()

    -- Trigger a force refresh for all widgets
    SketchyBar.exec("sleep 3", function()
      for name, _ in pairs(registered_timers) do
        SketchyBar.exec(SKETCHYBAR_EXECUTABLE .. " --trigger " .. name)
      end
    end)
  end)
end

return Timer