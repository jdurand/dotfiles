#!/bin/bash

# SketchyBar Hang Recovery Script
# Cleans up orphaned processes and restarts SketchyBar

set -euo pipefail

echo "🔧 SketchyBar Hang Recovery"
echo "=========================="

# Function to count processes
count_processes() {
  local pattern="$1"
  ps aux | grep -E "$pattern" | grep -v grep | wc -l | tr -d ' '
}

# Step 1: Kill orphaned timer processes
echo "Cleaning up timer processes..."
TIMER_COUNT=$(count_processes "sketchybar --trigger")
if [ "$TIMER_COUNT" -gt 0 ]; then
  echo "  Found $TIMER_COUNT timer processes"
  pkill -f 'sketchybar --trigger' 2>/dev/null || true
  sleep 0.5
  echo "  ✓ Timer processes killed"
else
  echo "  No timer processes found"
fi

# Step 2: Kill event providers
echo "Cleaning up event providers..."
EVENT_COUNT=$(count_processes "cpu_load|gpu_load")
if [ "$EVENT_COUNT" -gt 0 ]; then
  echo "  Found $EVENT_COUNT event provider processes"
  pkill -f 'cpu_load|gpu_load' 2>/dev/null || true
  sleep 0.5
  echo "  ✓ Event providers killed"
else
  echo "  No event providers found"
fi

# Step 3: Kill any stuck SketchyBar processes
echo "Checking for stuck SketchyBar processes..."
SKETCHYBAR_COUNT=$(count_processes "sketchybar$")
if [ "$SKETCHYBAR_COUNT" -gt 1 ]; then
  echo "  Found multiple SketchyBar instances"
  pkill -9 sketchybar 2>/dev/null || true
  sleep 1
  echo "  ✓ SketchyBar processes killed"
else
  echo "  SketchyBar appears normal"
fi

# Step 4: Restart SketchyBar
echo "Restarting SketchyBar..."
if pgrep -x "sketchybar" > /dev/null; then
  echo "  Reloading configuration..."
  /opt/homebrew/bin/sketchybar --reload
else
  echo "  Starting SketchyBar..."
  /opt/homebrew/bin/sketchybar &
  sleep 2
fi

# Step 5: Verify
echo ""
echo "Verification:"
echo "  SketchyBar processes: $(count_processes 'sketchybar$')"
echo "  Timer processes: $(count_processes 'sketchybar --trigger')"
echo "  Event providers: $(count_processes 'cpu_load|gpu_load')"

echo ""
echo "✅ Recovery complete!"