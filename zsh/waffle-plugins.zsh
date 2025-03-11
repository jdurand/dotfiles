#
# Custom Plugins
# -----------------------------------------------------------------------------

WAFFLE_PLUGIN_DIR="$HOME/.zsh/waffle-plugins"

function _initialize_waffle_plugin() {
  local plugin="$1"
  dir="$WAFFLE_PLUGIN_DIR/$(basename "$plugin")"

  if [ ! -d "$dir" ]; then
    echo "🧇  installing $plugin..."
    git clone "https://github.com/$plugin" "$dir" && _load_waffle_plugin $plugin
  fi
}

function _load_waffle_plugin() {
  local plugin="${1#*/}"
  local files=("$WAFFLE_PLUGIN_DIR/$plugin/$plugin.plugin.zsh" "$WAFFLE_PLUGIN_DIR/$plugin/$plugin.zsh")

  for file in "${files[@]}"; do
    if [ -f "$file" ]; then
      source "$file"
      return
    fi
  done

  _initialize_waffle_plugin $1
}

function _defer_load_waffle_plugin() {
  zsh-defer -a _load_waffle_plugin $1
}

function _update_waffle_plugins() {
  for dir in "$WAFFLE_PLUGIN_DIR/"*/; do
    if [ -d "$dir" ]; then
      plugin="$(basename "$dir")"
      echo "🧇 updating $plugin..."
      (cd "$dir" && git pull)
    fi
  done
}

function _cleanup_waffle_plugins() {
  # Get the list of repos to be recloned
  local current_dir=$(pwd)
  local directories_to_cleanup=()

  cd "${WAFFLE_PLUGIN_DIR}" || return

  for dir in *; do
    directories_to_cleanup+=("$dir")
  done

  # Remove each git repository using the repos array
  local plugins_to_install=()

  for dir in "${directories_to_cleanup[@]}"; do
    remote=$(git -C "$dir" remote get-url origin)
    repo=$(echo "$remote" | sed -E 's|.+/([^/]+/[^.]+)(\.git)?|\1|')
    plugins_to_install+=("$repo")

    echo "🧹 cleaning up $dir..."
    rm -rf "$dir"
  done
  
  # Reinitialize each repo
  # for plugin in "${plugins_to_install[@]}"; do
  #   _initialize_waffle_plugin $plugin
  # done

  cd $current_dir || return
}

function _waffle_help() {
  echo '👨🏾‍🍳 Waffle Plugins 🧇'
  echo 'Here are your delicious options:'
  echo '  cook    - Load a waffle plugin and start cooking!'
  echo '  syrup   - Update your waffle plugins for the freshest flavors!'
  echo '  stack   - Postpone loading a plugin for a more efficient breakfast!'
  echo '  clean   - Clean up leftover crumbs from your waffle stack!'
  echo '  help    - Get this help message and never get lost in the kitchen!'
  echo '  version - Check your waffle plugins version (deliciously fun)!'
}

function _waffle_version() {
  echo '👨🏾‍🍳 Waffle version 0.1 – Still cooking 🧇'
}

# Use zsh-defer to speed up prompt and delay non-essential scripts
_load_waffle_plugin "romkatv/zsh-defer"

function waffle() {
  typeset -A subcmds=(
    cook "_load_waffle_plugin"
    syrup "_update_waffle_plugins"
    stack "_defer_load_waffle_plugin"
    clean "_cleanup_waffle_plugins"
    help "_waffle_help"
    version "_waffle_version"
  )
  emulate -L zsh
  [[ -z "$subcmds[$1]" ]] && { _waffle_help; return 1 } || ${subcmds[$1]} $2
}
