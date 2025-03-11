# export function to load direnv

load_direnv() {
  if command -v direnv 1>/dev/null 2>&1; then
    eval "$(direnv hook zsh)"
  fi
}
