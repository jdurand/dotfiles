#
# Themes
# -----------------------------------------------------------------------------

# Set Oh My Zsh Theme
# ZSH_THEME="agnoster"
# ZSH_THEME="powerlevel10k/powerlevel10k"

# Use Powerlevel10k theme when using floaterm
if [[ -z "${ZSH_THEME}" ]]; then
  if [[ -n "${FLOATERM}" ]]; then
    ZSH_THEME="powerlevel10k/powerlevel10k"
  fi
fi

# Optionally load Powerlevel10k config
if [ "$ZSH_THEME" = "powerlevel10k/powerlevel10k" ]; then
  # Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
  # Initialization code that may require console input (password prompts, [y/n]
  # confirmations, etc.) must go above this block; everything else may go below.
  if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
  fi

  # Load Powerlevel10k config
  [[ ! -f ~/.zsh/p10k.zsh ]] || source ~/.zsh/p10k.zsh
fi

# Load Oh My Posh Themes if ZSH_THEME is not set
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
      # Use a simpler theme without a right prompt in floaterm, unless Powerlevel10k is configured.
      eval "$(oh-my-posh init zsh --config ~/.zsh/posh-themes/catppuccin.omp.json)"
    else
      eval "$(oh-my-posh init zsh --config ~/.zsh/posh-themes/catppuccin_mocha.omp.json)"
    fi
  fi
fi
