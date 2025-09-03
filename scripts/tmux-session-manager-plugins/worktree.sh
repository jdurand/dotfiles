#!/bin/bash

# Git Worktree Plugin for tmux-session-manager
# Manages sessions from git worktrees

plugin_meta() {
  echo "name:worktree"
  echo "description:Git worktree sessions"
  echo "priority:10"
  echo "depends:git"
  echo "install_cmd:git is usually pre-installed"
  echo "icon:○"
  echo "icon_color:BLUE"
}

plugin_discover() {
  local active_sessions="$1"
  local scratch_sessions="$2"
  local worktrees=""
  
  # Try current directory first
  if git rev-parse --git-dir &>/dev/null; then
    worktrees=$(git worktree list --porcelain 2>/dev/null | \
      awk '/^worktree/ {path = $2} /^branch/ {gsub(/^refs\/heads\//, "", $2); print path ":" $2}' | \
      while IFS=: read -r path branch; do
        # Skip the main worktree (current repo)
        if [[ "$path" != "$(git rev-parse --show-toplevel)" ]]; then
          basename "$path"
        fi
      done)
  fi
  
  # Also check from active session directories for additional worktrees
  if [[ -z "$worktrees" ]]; then
    while IFS= read -r session; do
      if [[ -n "$session" ]]; then
        local session_dir
        session_dir=$(tmux display-message -t "$session" -p "#{pane_current_path}" 2>/dev/null)
        if [[ -n "$session_dir" && -d "$session_dir" ]]; then
          local session_worktrees
          session_worktrees=$(cd "$session_dir" 2>/dev/null && git worktree list --porcelain 2>/dev/null | \
            awk '/^worktree/ {path = $2} /^branch/ {gsub(/^refs\/heads\//, "", $2); print path ":" $2}' | \
            while IFS=: read -r path branch; do
              if [[ "$path" != "$session_dir" ]]; then
                basename "$path"
              fi
            done)
          if [[ -n "$session_worktrees" ]]; then
            worktrees="$session_worktrees"
            break
          fi
        fi
      fi
    done <<< "$active_sessions"
  fi
  
  # Filter out active sessions and return available worktrees
  echo "$worktrees" | while IFS= read -r worktree; do
    if [[ -n "$worktree" ]] && ! echo "$active_sessions" | grep -q "^$worktree$" && ! echo "$scratch_sessions" | grep -q "^$worktree$"; then
      # Check if any active session is already running in this worktree's directory
      local worktree_path
      worktree_path=$(plugin_resolve_path "$worktree" "$active_sessions")
      if [[ -n "$worktree_path" ]] && ! is_worktree_path_active "$worktree_path" "$active_sessions"; then
        echo "$worktree"
      fi
    fi
  done
  return 0
}

plugin_resolve_path() {
  local session_name="$1"
  local active_sessions="$2"
  local worktree_path=""
  
  # Try current directory first
  if git rev-parse --git-dir &>/dev/null; then
    worktree_path=$(git worktree list --porcelain 2>/dev/null | \
      awk '/^worktree/ {path = $2} /^branch/ {gsub(/^refs\/heads\//, "", $2); print path ":" $2}' | \
      while IFS=: read -r path branch; do
        if [[ "$(basename "$path")" == "$session_name" ]]; then
          echo "$path"
          break
        fi
      done)
  fi
  
  # If not found, check from active session directories
  if [[ -z "$worktree_path" ]]; then
    while IFS= read -r session; do
      if [[ -n "$session" ]]; then
        local session_dir
        session_dir=$(tmux display-message -t "$session" -p "#{pane_current_path}" 2>/dev/null)
        if [[ -n "$session_dir" && -d "$session_dir" ]]; then
          worktree_path=$(cd "$session_dir" 2>/dev/null && git worktree list --porcelain 2>/dev/null | \
            awk '/^worktree/ {path = $2} /^branch/ {gsub(/^refs\/heads\//, "", $2); print path ":" $2}' | \
            while IFS=: read -r path branch; do
              if [[ "$(basename "$path")" == "$session_name" ]]; then
                echo "$path"
                break
              fi
            done)
          if [[ -n "$worktree_path" ]]; then
            break
          fi
        fi
      fi
    done <<< "$active_sessions"
  fi
  
  echo "$worktree_path"
}

is_worktree_path_active() {
  local worktree_path="$1"
  local active_sessions="$2"
  
  while IFS= read -r session; do
    if [[ -n "$session" ]]; then
      local session_dir
      session_dir=$(tmux display-message -t "$session" -p "#{pane_current_path}" 2>/dev/null)
      if [[ -n "$session_dir" && "$session_dir" == "$worktree_path" ]]; then
        return 0  # Found matching session
      fi
    fi
  done <<< "$active_sessions"
  return 1  # No matching session found
}

plugin_resolve() {
  local session_name="$1"
  local active_sessions="$2"
  
  local worktree_path
  worktree_path=$(plugin_resolve_path "$session_name" "$active_sessions")
  
  if [[ -n "$worktree_path" && -d "$worktree_path" ]]; then
    echo "type:worktree"
    echo "worktree_path:$worktree_path"
    echo "exists:true"
    
    # Get branch info if possible
    if cd "$worktree_path" 2>/dev/null; then
      local branch
      branch=$(git branch --show-current 2>/dev/null || echo "unknown")
      echo "branch:$branch"
    fi
  else
    echo "exists:false"
  fi
}

plugin_switch() {
  local session_name="$1"
  local metadata="$2"
  local active_sessions="$3"
  local tmuxinator_plugins="$4"
  
  local worktree_path
  worktree_path=$(echo "$metadata" | grep "^worktree_path:" | cut -d: -f2-)
  
  if [[ -n "$worktree_path" && -d "$worktree_path" ]]; then
    # Check if there's a matching tmuxinator config for this worktree
    local matching_config=""
    if [[ -n "$tmuxinator_plugins" ]]; then
      while IFS= read -r config; do
        if [[ -n "$config" ]]; then
          local config_metadata
          config_metadata=$("$tmuxinator_plugins" resolve "$config")
          local config_root
          config_root=$(echo "$config_metadata" | grep "^root_path:" | cut -d: -f2-)
          if [[ -n "$config_root" && "$config_root" == "$worktree_path" ]]; then
            matching_config="$config"
            break
          fi
        fi
      done <<< "$("$tmuxinator_plugins" discover "$active_sessions" "")"
    fi
    
    if [[ -n "$matching_config" ]] && command -v tmuxinator &> /dev/null; then
      # Use tmuxinator if available
      tmuxinator start "$matching_config"
      if [[ -n "${TMUX:-}" ]]; then
        tmux switch-client -t "$matching_config" 2>/dev/null || true
      fi
    else
      # Create new session in the worktree directory
      if [[ -n "${TMUX:-}" ]]; then
        tmux new-session -d -s "$session_name" -c "$worktree_path"
        tmux switch-client -t "$session_name"
      else
        tmux new-session -s "$session_name" -c "$worktree_path"
      fi
    fi
  else
    echo "ERROR:Worktree path not found for $session_name"
    return 1
  fi
}

plugin_preview() {
  local session_name="$1"
  local metadata="$2"
  
  echo "${BLUE}Git Worktree: $session_name${NC}"
  echo ""
  
  local worktree_path
  worktree_path=$(echo "$metadata" | grep "^worktree_path:" | cut -d: -f2-)
  
  if [[ -n "$worktree_path" && -d "$worktree_path" ]]; then
    echo "${YELLOW}Worktree path:${NC}"
    echo "$worktree_path"
    echo ""
    
    if cd "$worktree_path" 2>/dev/null; then
      echo "${YELLOW}Branch info:${NC}"
      git branch --show-current 2>/dev/null || echo "  Could not determine branch"
      echo ""
      echo "${YELLOW}Recent commits:${NC}"
      git log --oneline -5 2>/dev/null | sed 's/^/  /' || echo "  Could not read git log"
      echo ""
      echo "${YELLOW}Working directory status:${NC}"
      git status --porcelain 2>/dev/null | head -10 | sed 's/^/  /' || echo "  Clean working directory"
    else
      echo "Could not access worktree directory"
    fi
  else
    echo "Worktree path not found"
  fi
}

plugin_indicator() {
  local session_name="$1"
  local is_current="$2"
  local is_active="$3"
  
  if [[ "$is_current" == "true" ]]; then
    echo "${BLUE}→${NC}"
  elif [[ "$is_active" == "true" ]]; then
    echo "${BLUE}●${NC}"
  else
    echo "${BLUE}○${NC}"
  fi
}