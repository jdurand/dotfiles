#!/bin/bash

# SketchyBar Hang Recovery Script
# Cleans up orphaned processes and restarts SketchyBar

set -euo pipefail

echo "SketchyBar Hang Recovery"
echo "========================"

# Function to count processes
count_processes() {
  local pattern="$1"
  ps aux | grep -E "$pattern" | grep -v grep | wc -l | tr -d ' '
}

# Step 1: Kill timer manager processes
echo "Cleaning up timer manager..."
TIMER_MGR_COUNT=$(count_processes "sketchybar_timer_manager")
if [ "$TIMER_MGR_COUNT" -gt 0 ]; then
  echo "  Found $TIMER_MGR_COUNT timer manager processes"
  pkill -f 'sketchybar_timer_manager' 2>/dev/null || true
  sleep 0.5
  echo "  Done"
else
  echo "  No timer manager processes found"
fi

# Step 2: Kill orphaned timer trigger processes
echo "Cleaning up timer processes..."
TIMER_COUNT=$(count_processes "sketchybar --trigger")
if [ "$TIMER_COUNT" -gt 0 ]; then
  echo "  Found $TIMER_COUNT timer processes"
  pkill -f 'sketchybar --trigger' 2>/dev/null || true
  sleep 0.5
  echo "  Done"
else
  echo "  No timer processes found"
fi

# Step 3: Kill event providers
echo "Cleaning up event providers..."
EVENT_COUNT=$(count_processes "cpu_load|network_load")
if [ "$EVENT_COUNT" -gt 0 ]; then
  echo "  Found $EVENT_COUNT event provider processes"
  pkill -f 'cpu_load|network_load' 2>/dev/null || true
  sleep 0.5
  echo "  Done"
else
  echo "  No event providers found"
fi

# Step 4: Kill volume monitoring loops
echo "Cleaning up volume monitoring loops..."
VOLUME_COUNT=$(count_processes "osascript.*volume")
if [ "$VOLUME_COUNT" -gt 0 ]; then
  echo "  Found $VOLUME_COUNT volume monitoring loops"
  pkill -f 'osascript.*volume' 2>/dev/null || true
  sleep 0.5
  echo "  Done"
else
  echo "  No volume monitoring loops found"
fi

# Step 5: Kill watchdog loops (they use 'while true' with watchdog_check)
echo "Cleaning up watchdog loops..."
WATCHDOG_COUNT=$(count_processes "watchdog_check")
if [ "$WATCHDOG_COUNT" -gt 0 ]; then
  echo "  Found $WATCHDOG_COUNT watchdog processes"
  pkill -f 'watchdog_check' 2>/dev/null || true
  sleep 0.5
  echo "  Done"
else
  echo "  No watchdog processes found"
fi

# Step 6: Kill any stuck SketchyBar processes
echo "Checking for stuck SketchyBar processes..."
SKETCHYBAR_COUNT=$(count_processes "sketchybar$")
if [ "$SKETCHYBAR_COUNT" -gt 1 ]; then
  echo "  Found multiple SketchyBar instances"
  pkill -9 sketchybar 2>/dev/null || true
  sleep 1
  echo "  Done"
else
  echo "  SketchyBar appears normal"
fi

# Step 7: Restart SketchyBar
echo "Restarting SketchyBar..."
if pgrep -x "sketchybar" > /dev/null; then
  echo "  Reloading configuration..."
  /opt/homebrew/bin/sketchybar --reload
else
  echo "  Starting SketchyBar..."
  /opt/homebrew/bin/sketchybar &
  sleep 2
fi

# Step 8: Verify
echo ""
echo "Verification:"
echo "  SketchyBar processes: $(count_processes 'sketchybar$')"
echo "  Timer manager: $(count_processes 'sketchybar_timer_manager')"
echo "  Timer processes: $(count_processes 'sketchybar --trigger')"
echo "  Event providers: $(count_processes 'cpu_load|network_load')"
echo "  Volume loops: $(count_processes 'osascript.*volume')"
echo "  Watchdog loops: $(count_processes 'watchdog_check')"

echo ""
echo "Recovery complete!"