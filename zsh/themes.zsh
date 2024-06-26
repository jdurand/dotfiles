#
# Themes
# -----------------------------------------------------------------------------

#
# Load Oh My Zsh Plugins
# first run: ZSH=~/.dotfiles/vendor/oh-my-zsh sh -c "$(curl -fsSL https://install.ohmyz.sh/)"
# -----------------------------------------------------------------------------
export ZSH=~/.dotfiles/vendor/oh-my-zsh

# Load Oh My Zsh theme
# ZSH_THEME="agnoster"
# ZSH_THEME="powerlevel10k/powerlevel10k"

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
# plugins=(git zsh-iterm-touchbar)
plugins=(battery gh jira nvm direnv vi-mode zoxide)

source $ZSH/oh-my-zsh.sh

#
# Load Oh My Posh Themes
# first run: brew install jandedobbeleer/oh-my-posh/oh-my-posh
# -----------------------------------------------------------------------------

if [[ -z "${ZSH_THEME}" ]]; then
  if [ "$TERM_PROGRAM" != "Apple_Terminal" ]; then
    # eval "$(oh-my-posh init zsh)"
    # eval "$(oh-my-posh init zsh --config $(brew --prefix oh-my-posh)/themes/agnoster.omp.json)"
    # eval "$(oh-my-posh init zsh --config $(brew --prefix oh-my-posh)/themes/catppuccin.omp.json)"
    # eval "$(oh-my-posh init zsh --config $(brew --prefix oh-my-posh)/themes/catppuccin_mocha.omp.json)"
    # eval "$(oh-my-posh init zsh --config $(brew --prefix oh-my-posh)/themes/powerlevel10k_modern.omp.json)"

    if [[ -z "${FLOATERM}" ]]; then
      # use simpler theme without right prompt when rendered within floaterm
      eval "$(oh-my-posh init zsh --config ~/.zsh/posh-themes/catppuccin.omp.json)"
    else
      eval "$(oh-my-posh init zsh --config ~/.zsh/posh-themes/catppuccin_mocha.omp.json)"
    fi
  fi
fi

# Optionally load powerlevel10k config
if [[ -z "${POSH_THEME}" ]]; then
  if [ "$ZSH_THEME" = "powerlevel10k/powerlevel10k" ]; then
    [[ ! -f ~/.zsh/p10k.zsh ]] || source ~/.zsh/p10k.zsh
  fi
fi

# Load catppuccin syntax highlights
source ~/.zsh/syntax-highlight/catppuccin_mocha-zsh-syntax-highlighting.zsh
