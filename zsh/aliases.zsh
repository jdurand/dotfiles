#
# Aliases
# -----------------------------------------------------------------------------

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='nvim'

  alias oldvim=$(which vim)
  alias vim=nvim
  alias vi=nvim
  alias v=nvim
fi

# Use 'eza' as the default command for 'ls' with icons always enabled
alias ls="eza --icons=always"
# alias ls="eza --icons=always --long --git"

# Alias 'cd' to 'z' for efficient directory switching using 'zoxide'
eval "$(zoxide init zsh)"
alias cd="z"

# Simplify tmuxinator invocation
alias mux=tmuxinator

# Lazy alias for lazygit
alias ggit=lazygit

# alias func='ghprs'
# function gitprs() {
#   'gh pr list --search "status:success" --draft=false'
# }

# use Ag instead of Ack
alias ack=ag

# MacOS aliases
if [[ "$OSTYPE" == "darwin"* ]]; then
  # Use meld as git mergetool if not already defined
  if [[ -z "$(command -v meld)" ]]; then
    alias meld=/Applications/Meld.app/Contents/MacOS/Meld
  fi
fi

# wrapper to change directories upon Yazi exit
function y() {
  local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
  yazi "$@" --cwd-file="$tmp"
  if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
    builtin cd -- "$cwd"
  fi
  rm -f -- "$tmp"
}
