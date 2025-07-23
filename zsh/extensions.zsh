#
# Extensions and Plugins
# -----------------------------------------------------------------------------

source ~/.zsh/waffle-plugins.zsh # depends on zsh-defer

# zsh-defer waffle munch "zsh-fzf-history-search"
waffle stack "joshskidmore/zsh-fzf-history-search"
zsh-defer plug "zsh-users/zsh-autosuggestions"
zsh-defer plug "zsh-users/zsh-syntax-highlighting"

# Load add-zsh-hook to easily manage pre- and post-event functions
autoload -U add-zsh-hook

# Load fzf zsh extension
if command -v rbenv 1>/dev/null 2>&1; then
  eval "$(fzf --zsh)"
fi

for file in ~/.zsh/extensions/*; do
  [[ -f $file ]] && source "$file"
done

if [[ -n "${FLOATERM}" ]]; then
  zsh-defer load_rbenv
  zsh-defer load_direnv
else
  load_rbenv
  load_direnv
fi

zsh-defer load_iterm_integration
zsh-defer -t 2 load_pyenv

# Load current node.js version on zsh startup
if [[ -f package.json ]]; then
  zsh-defer nvm use
fi

# Refresh theme to display extensions
load_theme
