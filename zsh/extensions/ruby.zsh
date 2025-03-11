# export function to load rbenv

load_rbenv() {
  if command -v rbenv 1>/dev/null 2>&1; then
    eval "$(rbenv init -)"
  fi
}
