#
# Themes
# -----------------------------------------------------------------------------

# Set Oh My Zsh Theme
# ZSH_THEME="agnoster"
# ZSH_THEME="robbyrussell"
ZSH_THEME="powerlevel10k/powerlevel10k"

# Always use Powerlevel10k theme when using floaterm
if [[ -z "${ZSH_THEME}" ]]; then
  if [[ -n "${FLOATERM}" ]]; then
    ZSH_THEME="powerlevel10k/powerlevel10k"
  fi
fi

# When theme is Powerlevel10k, load Powerlevel10k config
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

# When ZSH_THEME is unset, load Oh My Posh Theme
# first run: brew install jandedobbeleer/oh-my-posh/oh-my-posh
# -----------------------------------------------------------------------------
if [[ -z "${ZSH_THEME}" ]]; then
  if [ "$TERM_PROGRAM" != "Apple_Terminal" ]; then
    # eval "$(oh-my-posh init zsh)"

    # eval "$(oh-my-posh init zsh --config $(brew --prefix oh-my-posh)/themes/agnoster.omp.json)"
    # eval "$(oh-my-posh init zsh --config $(brew --prefix oh-my-posh)/themes/catppuccin.omp.json)"
    # eval "$(oh-my-posh init zsh --config $(brew --prefix oh-my-posh)/themes/catppuccin_mocha.omp.json)"
    # eval "$(oh-my-posh init zsh --config $(brew --prefix oh-my-posh)/themes/powerlevel10k_modern.omp.json)"

    # eval "$(oh-my-posh init zsh --config ~/.zsh/posh-themes/catppuccin.omp.json)"
    # eval "$(oh-my-posh init zsh --config ~/.zsh/posh-themes/catppuccin_mocha.omp.json)"
    # eval "$(oh-my-posh init zsh --config ~/.zsh/posh-themes/zen.omp.toml)"
    eval "$(oh-my-posh init zsh --config ~/.zsh/posh-themes/electric-neon.omp.toml)"
  fi
fi
