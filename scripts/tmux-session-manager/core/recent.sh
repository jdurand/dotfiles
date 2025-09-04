#!/bin/bash

# Recent Session Core Plugin for tmux-session-manager  
# Handles the most recently active session with highest priority

plugin_meta() {
  echo "name:recent"
  echo "description:Most recently active session"
  echo "depends:tmux"
  echo "install_cmd:brew install tmux"
  echo "icon:★"
  echo "icon_color:BRIGHT_YELLOW"
  echo "sort_priority:1"
}

plugin_discover() {
  local active_sessions="$1"
  local scratch_sessions="$2" 
  local current_session="$3"
  
  # Get the most recent session that is NOT the current session
  local most_recent
  most_recent=$(echo "$active_sessions" | while IFS= read -r session; do
    if [[ -n "$session" && "$session" != "$current_session" ]] && ! echo "$session" | grep -q "scratch"; then
      echo "$session"
      break
    fi
  done)
  
  # Return the most recent non-current session
  if [[ -n "$most_recent" ]]; then
    echo "$most_recent"
  fi
}

plugin_resolve() {
  local session_name="$1"
  
  if tmux has-session -t "$session_name" 2>/dev/null; then
    local session_dir
    session_dir=$(tmux display-message -t "$session_name" -p "#{pane_current_path}" 2>/dev/null)
    
    echo "type:recent"
    echo "session_dir:$session_dir"
    echo "exists:true"
    echo "is_most_recent:true"
    
    # Check if it's in a worktree for enhanced display
    if [[ -n "$session_dir" && -d "$session_dir" && -f "$session_dir/.git" ]]; then
      if grep -q "gitdir:" "$session_dir/.git" 2>/dev/null; then
        echo "in_worktree:true"
      else
        echo "in_worktree:false"
      fi
    else
      echo "in_worktree:false"
    fi
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
    echo "${RED}Session '$session_name' is not active${NC}"
    echo ""
    echo "This session will be created when selected."
    return
  fi
  
  # Show enhanced preview for most recent session
  local active_window active_pane
  active_window=$(tmux list-windows -t "$session_name" -f '#{window_active}' -F "#{window_index}" 2>/dev/null | head -1)
  
  if [[ -n "$active_window" ]]; then
    active_pane=$(tmux list-panes -t "$session_name:$active_window" -f '#{pane_active}' -F "#{pane_index}" 2>/dev/null | head -1)
    
    if [[ -n "$active_pane" ]]; then
      # Show session header with most recent indicator
      echo "${BRIGHT_YELLOW}★ $session_name${NC} ${DARK_GREY}(most recent)${NC} (${YELLOW}$(tmux list-windows -t "$session_name" | wc -l | tr -d ' ') windows${NC})"
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
  local metadata="$4"
  
  # Recent session uses star indicator
  local in_worktree
  in_worktree=$(echo "$metadata" | grep "^in_worktree:" | cut -d: -f2)
  
  if [[ "$is_current" == "true" ]]; then
    if [[ "$in_worktree" == "true" ]]; then
      echo "${BLUE}→${NC}"  # Current worktree recent session
    else
      echo "${BRIGHT_YELLOW}→${NC}"  # Current recent session
    fi
  else
    if [[ "$in_worktree" == "true" ]]; then
      echo "${BLUE}★${NC}"  # Recent worktree session
    else
      echo "${BRIGHT_YELLOW}★${NC}"  # Recent session
    fi
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