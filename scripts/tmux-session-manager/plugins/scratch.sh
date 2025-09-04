#!/bin/bash

# Scratch Sessions Plugin for tmux-session-manager
# Manages temporary/scratch tmux sessions

plugin_meta() {
  echo "name:scratch"
  echo "description:Scratch/temporary sessions"
  echo "depends:tmux"
  echo "install_cmd:brew install tmux"
  echo "icon:󱗽"
  echo "active_icon:󱗽"
  echo "icon_color:GREEN"
  echo "sort_priority:999"
}

plugin_discover() {
  local active_sessions="$1"
  local scratch_sessions="$2"
  local current_session="$3"
  
  # Get all tmux sessions and filter for scratch sessions
  local all_sessions
  all_sessions=$(tmux list-sessions -F "#{session_name}" 2>/dev/null || true)
  
  # Return sessions that contain "scratch" in the name
  echo "$all_sessions" | while IFS= read -r session; do
    if [[ -n "$session" && "$session" == *"scratch"* ]]; then
      if [[ "$session" == "$current_session" ]]; then
        echo "$session:current"
      else
        echo "$session"
      fi
    fi
  done
}

plugin_resolve() {
  local session_name="$1"
  
  if tmux has-session -t "$session_name" 2>/dev/null; then
    local session_dir
    session_dir=$(tmux display-message -t "$session_name" -p "#{pane_current_path}" 2>/dev/null)
    
    echo "type:scratch"
    echo "session_dir:$session_dir"
    echo "exists:true"
  else
    echo "exists:false"
  fi
}

plugin_switch() {
  local session_name="$1"
  local metadata="$2"
  
  if [[ -n "${TMUX:-}" ]]; then
    tmux switch-client -t "$session_name"
  else
    tmux attach-session -t "$session_name"
  fi
}

plugin_preview() {
  local session_name="$1"
  local metadata="$2"
  
  # Check if session is active
  if ! tmux has-session -t "$session_name" 2>/dev/null; then
    echo "${RED}Scratch session '$session_name' is not active${NC}"
    echo ""
    echo "This session will be created when selected."
    return
  fi
  
  # Show live session content using tmux capture-pane
  local active_window active_pane
  active_window=$(tmux list-windows -t "$session_name" -f '#{window_active}' -F "#{window_index}" 2>/dev/null | head -1)
  
  if [[ -n "$active_window" ]]; then
    active_pane=$(tmux list-panes -t "$session_name:$active_window" -f '#{pane_active}' -F "#{pane_index}" 2>/dev/null | head -1)
    
    if [[ -n "$active_pane" ]]; then
      # Show session header info
      echo "${GREEN}󱗽 $session_name${NC} (${YELLOW}$(tmux list-windows -t "$session_name" | wc -l | tr -d ' ') windows${NC}) ${DARK_GREY}[scratch]${NC}"
      echo "${DARK_GREY}────────────────────────────────────────${NC}"
      
      # Capture live pane content
      tmux capture-pane -ep -t "$session_name:$active_window.$active_pane" 2>/dev/null || {
        echo "${RED}Could not capture session content${NC}"
        echo "Session may be busy or inaccessible"
      }
    else
      echo "${RED}No active pane found in session${NC}"
    fi
  else
    echo "${RED}No active window found in session${NC}"
  fi
}

plugin_indicator() {
  local session_name="$1"
  local is_current="$2"
  local is_active="$3"
  
  if [[ "$is_current" == "true" ]]; then
    echo "${GREEN}→${NC}"
  else
    echo "${GREEN}󱗽${NC}"
  fi
}

plugin_kill() {
  local session_name="$1"
  
  if tmux has-session -t "$session_name" 2>/dev/null; then
    tmux kill-session -t "$session_name" 2>/dev/null || true
  fi
}

plugin_rename() {
  local session_name="$1"
  
  if tmux has-session -t "$session_name" 2>/dev/null; then
    tmux command-prompt -p "Rename session '$session_name' to:" \
      "rename-session -t '$session_name' '%%'" 2>/dev/null || true
  fi
}
