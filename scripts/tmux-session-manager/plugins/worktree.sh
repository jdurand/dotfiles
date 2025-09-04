#!/bin/bash

# Git Worktree Plugin for tmux-session-manager
# Manages sessions from git worktrees

plugin_meta() {
  echo "name:worktree"
  echo "description:Git worktree sessions"
  echo "depends:git"
  echo "install_cmd:git is usually pre-installed"
  echo "icon:○"
  echo "icon_color:BLUE"
  echo "sort_priority:5"
}

plugin_discover() {
  local active_sessions="$1"
  local scratch_sessions="$2"
  local current_session="$3"

  # Get all tmux sessions and check which ones are in worktree directories
  local all_sessions
  all_sessions=$(tmux list-sessions -F "#{session_name}" 2>/dev/null || true)
  
  local discovered_worktrees=()
  
  # Method 1: Check all active sessions for worktree directories
  while IFS= read -r session; do
    if [[ -n "$session" ]]; then
      local session_dir
      session_dir=$(tmux display-message -t "$session" -p "#{pane_current_path}" 2>/dev/null || true)
      if [[ -n "$session_dir" && -f "$session_dir/.git" ]] && grep -q "gitdir:" "$session_dir/.git" 2>/dev/null; then
        # This is a worktree session
        discovered_worktrees+=("$session")
      fi
    fi
  done <<< "$all_sessions"

  # Method 2: If we're in a git repo, discover worktrees that don't have sessions yet
  local current_session_dir=""
  if [[ -n "$current_session" ]]; then
    current_session_dir=$(tmux display-message -t "$current_session" -p "#{pane_current_path}" 2>/dev/null || true)
  fi
  
  if [[ -z "$current_session_dir" ]]; then
    current_session_dir="$(pwd)"
  fi
  
  local original_dir="$(pwd)"
  if cd "$current_session_dir" 2>/dev/null; then
    if git rev-parse --git-dir &>/dev/null; then
      local current_repo_root
      current_repo_root=$(git rev-parse --show-toplevel)
      
      # Find inactive worktrees from current repo
      git worktree list --porcelain 2>/dev/null | \
        awk '/^worktree/ {path = $2} /^branch/ {gsub(/^refs\/heads\//, "", $2); print path}' | \
        while IFS= read -r path; do
          if [[ "$path" != "$current_repo_root" ]]; then
            local worktree_name
            worktree_name=$(basename "$path")
            # Only add if no session exists for this worktree
            local has_session=false
            for existing in "${discovered_worktrees[@]}"; do
              if [[ "$existing" == "$worktree_name" ]]; then
                has_session=true
                break
              fi
            done
            if [[ "$has_session" == "false" ]]; then
              discovered_worktrees+=("$worktree_name")
            fi
          fi
        done
    fi
    cd "$original_dir" 2>/dev/null
  fi

  # Output discovered worktrees
  for session in "${discovered_worktrees[@]}"; do
    if [[ "$session" == "$current_session" ]]; then
      echo "${session}:current"
    else
      echo "$session"
    fi
  done
}

plugin_resolve() {
  local session_name="$1"
  local active_sessions="$2"
  local scratch_sessions="$3"
  
  local original_dir="$(pwd)"
  local worktree_path=""
  
  # Method 1: If the session already exists, get its current path
  if tmux has-session -t "$session_name" 2>/dev/null; then
    local session_dir
    session_dir=$(tmux display-message -t "$session_name" -p "#{pane_current_path}" 2>/dev/null || true)
    if [[ -n "$session_dir" && -f "$session_dir/.git" ]] && grep -q "gitdir:" "$session_dir/.git" 2>/dev/null; then
      # This is an existing worktree session
      worktree_path="$session_dir"
    fi
  fi
  
  # Method 2: If no existing session, search from current directory or current session
  if [[ -z "$worktree_path" ]]; then
    local current_session=""
    if [[ -n "${TMUX:-}" ]]; then
      current_session=$(tmux display-message -p "#{session_name}")
    fi
    
    local current_session_dir=""
    if [[ -n "$current_session" ]]; then
      current_session_dir=$(tmux display-message -t "$current_session" -p "#{pane_current_path}" 2>/dev/null || true)
    fi
    
    if [[ -z "$current_session_dir" ]]; then
      current_session_dir="$(pwd)"
    fi
    
    if cd "$current_session_dir" 2>/dev/null; then
      if git rev-parse --git-dir &>/dev/null; then
        # Find worktree path for the session
        worktree_path=$(git worktree list --porcelain 2>/dev/null | \
          awk '/^worktree/ {path = $2} /^branch/ {gsub(/^refs\/heads\//, "", $2); print path ":" $2}' | \
          while IFS=: read -r path branch; do
            if [[ "$(basename "$path")" == "$session_name" ]]; then
              echo "$path"
              break
            fi
          done)
      fi
      cd "$original_dir" 2>/dev/null
    fi
  fi
  
  if [[ -n "$worktree_path" && -d "$worktree_path" ]]; then
    echo "type:worktree"
    echo "worktree_path:$worktree_path"
    echo "exists:true"
    
    # Get branch info if possible
    if cd "$worktree_path" 2>/dev/null; then
      local branch
      branch=$(git branch --show-current 2>/dev/null || echo "unknown")
      echo "branch:$branch"
      cd "$original_dir" 2>/dev/null
    fi
  else
    echo "exists:false"
  fi
}

plugin_switch() {
  local session_name="$1"
  local metadata="$2"
  
  local worktree_path
  worktree_path=$(echo "$metadata" | grep "^worktree_path:" | cut -d: -f2-)
  
  if [[ -n "$worktree_path" && -d "$worktree_path" ]]; then
    # Create or switch to session in the worktree directory
    if tmux has-session -t "$session_name" 2>/dev/null; then
      # Session exists, just switch
      if [[ -n "${TMUX:-}" ]]; then
        tmux switch-client -t "$session_name"
      else
        tmux attach-session -t "$session_name"
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
    echo "Worktree path not found for $session_name" >&2
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
