#!/bin/bash

# Tmuxinator Plugin for tmux-session-manager
# Manages sessions from tmuxinator configuration files

plugin_meta() {
  echo "name:tmuxinator"
  echo "description:Tmuxinator configuration sessions"
  echo "depends:tmuxinator"
  echo "install_cmd:brew install tmuxinator"
  echo "icon:●"
  echo "icon_color:DARK_GREY"
  echo "sort_priority:50"
}

plugin_discover() {
  local active_sessions="$1"
  local scratch_sessions="$2"
  
  if [[ -d "$HOME/.dotfiles/tmuxinator" ]]; then
    find "$HOME/.dotfiles/tmuxinator" -name "*.yml" -exec basename {} .yml \; | grep -v config | \
    while IFS= read -r config; do
      # Exclude if already active
      if [[ -n "$config" ]] && ! echo "$active_sessions" | grep -q "^$config$" && ! echo "$scratch_sessions" | grep -q "^$config$"; then
        echo "$config"
      fi
    done
  fi
}

plugin_resolve() {
  local session_name="$1"
  local config_file="$HOME/.dotfiles/tmuxinator/$session_name.yml"
  
  if [[ -f "$config_file" ]]; then
    # Extract and expand root path
    local root_path
    root_path=$(grep "^root:" "$config_file" 2>/dev/null | sed 's/^root: *//' | tr -d '"' | head -1)
    root_path="${root_path/#\~/$HOME}"
    
    echo "type:tmuxinator"
    echo "config_file:$config_file"
    echo "root_path:$root_path"
    echo "exists:true"
  else
    echo "exists:false"
  fi
}

plugin_switch() {
  local session_name="$1"
  local metadata="$2"
  
  if ! command -v tmuxinator &> /dev/null; then
    echo "ERROR:tmuxinator command not found"
    return 1
  fi
  
  tmuxinator start "$session_name"
  
  # Switch to the newly created session if inside tmux
  if [[ -n "${TMUX:-}" ]]; then
    tmux switch-client -t "$session_name" 2>/dev/null || true
  fi
}

plugin_preview() {
  local session_name="$1"
  local metadata="$2"
  
  echo "${BLUE}Tmuxinator Configuration: $session_name${NC}"
  echo ""
  
  local config_file
  config_file=$(echo "$metadata" | grep "^config_file:" | cut -d: -f2-)
  
  if [[ -f "$config_file" ]]; then
    echo "${YELLOW}Configuration file:${NC}"
    echo "$config_file"
    echo ""
    echo "${YELLOW}Config preview:${NC}"
    head -20 "$config_file" 2>/dev/null | sed 's/^/  /' || echo "  Could not read config file"
  else
    echo "Configuration file not found"
  fi
}

plugin_start_background() {
  local session_name="$1"
  
  if command -v tmuxinator &> /dev/null; then
    tmuxinator start "$session_name" --no-attach 2>/dev/null || true
  fi
}

plugin_indicator() {
  local session_name="$1"
  local is_current="$2"
  local is_active="$3"
  
  if [[ "$is_current" == "true" ]]; then
    echo "${DARK_GREY}→${NC}"
  elif [[ "$is_active" == "true" ]]; then
    echo "${DARK_GREY}●${NC}"
  else
    echo "${DARK_GREY}●${NC}"
  fi
}
