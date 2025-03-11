# export function to load iTerm integration

load_iterm_integration() {
  # Load iTerm2 shell integration only if in iTerm
  if [[ "$TERM_PROGRAM" == "iTerm.app" ]]; then
    test -e "${HOME}/.iterm2_shell_integration.zsh" && plug "${HOME}/.iterm2_shell_integration.zsh"
  fi
}

