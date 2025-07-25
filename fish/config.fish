# fish configuration

# Set environment variables
# ------------------------------------------------------------------------------
set -x PATH $PATH $HOME/.local/bin
set -x PATH $PATH $HOME/go/bin
set -x PATH $PATH $ANDROID_HOME/emulator
set -x PATH $PATH $ANDROID_HOME/platform-tools

set -x ANDROID_HOME $HOME/Library/Android/sdk
set -x LG_CONFIG_FILE "$HOME/.config/lazygit/config.yml"
set -x QMK_HOME "$HOME/Code/keyboards/qmk_firmware"
set -x QMK_FIRMWARE "$HOME/Code/keyboards/qmk_firmware"

set -x CONDA_AUTO_ACTIVATE_BASE false
set -x HISTFILE $HOME/.zhistory
set -x HISTSIZE 1000000
set -x SAVEHIST 1000000
set -x TZ "America/Montreal"
set -x LANG "en_US.UTF-8"
set -x LC_ALL $LANG
set -x MANPAGER "sh -c 'col -bx | bat -l man -p'"
set -x EDITOR 'nvim'

# Set environment variables for Rails with Puma in clustered mode.
# OBJC_DISABLE_INITIALIZE_FORK_SAFETY: Disables the Objective-C runtime's safety checks when forking processes,
# allowing better compatibility with multi-threaded servers like Puma.
set -x OBJC_DISABLE_INITIALIZE_FORK_SAFETY "YES"
# PGGSSENCMODE: Disables GSSAPI encryption for PostgreSQL connections,
# which can help prevent authentication issues in clustered environments.
set -x PGGSSENCMODE "disable"

# qlty
set -x QLTY_INSTALL "$HOME/.qlty"
set -x PATH $QLTY_INSTALL/bin $PATH

# Add homebrew bins to $PATH
if test -e /opt/homebrew/bin/brew
  /opt/homebrew/bin/brew shellenv | source
else if test -e /home/linuxbrew/.linuxbrew/bin/brew
  /home/linuxbrew/.linuxbrew/bin/brew shellenv | source
else if test -e /usr/local/bin/brew
  /usr/local/bin/brew shellenv | source
else if test -e brew
  brew shellenv | source
else
  return 1
end

# Plugins
# ------------------------------------------------------------------------------

# Initialize Starship prompt
function starship_transient_prompt_func
  starship module character
end
# function starship_transient_rprompt_func
#   starship module cmd_duration
# end
if type -q starship; starship init fish | source; end
enable_transience

# Initialize rbenv
if type -q rbenv; rbenv init - | source; end

# Initialize fuzzy finder
if type -q fzf; fzf --fish | source; end

# Initialize zoxide for fast directory jumping
if type -q zoxide; zoxide init fish | source; end

# # Initialize conda
# eval $HOME/opt/anaconda3/bin/conda "shell.fish" "hook" $argv | source

# Update node version based on local .nvmrc
function nvm_auto_use --on-variable PWD
  if test -e .nvmrc
    set -l node_version (cat .nvmrc)
    if test (nvm current) != "v$node_version"
      nvm use
    end
  end
end

# Initialize direnv
if type -q direnv; direnv hook fish | source; end

# Load git fzf functions
source (dirname (realpath (status --file)))'/../fzf/extensions/fzf-git.fish'

# Aliases
# ------------------------------------------------------------------------------
alias vim='nvim'
alias vi='nvim'
alias v='nvim'
alias cd='z'
alias ggit='lazygit'
alias ack='ag'
alias ls='eza --icons=always'
alias cat='bat --paging=never'
alias mux='tmuxinator'

# Keybindings
# ------------------------------------------------------------------------------

# FZF keybindings
#
# fzf.fish
fzf_configure_bindings --history=\cr --directory=\cf --variables=\cv --processes=\cp

# git.fzf.fish
setup_git_fzf_key_bindings

# Vim mode
# -----------------------
# enable vim key bindings
fish_vi_key_bindings

# Normal mode key bindings
#
# copy the current line to the clipboard
bind yy fish_clipboard_copy

# copy the visual selection to the clipboard
bind -s --preset -M visual -m default y 'fish_clipboard_copy; commandline -f end-selection repaint-mode'

# paste content from the clipboard
bind p fish_clipboard_paste

# Preferences
# ------------------------------------------------------------------------------

# disable fish greeting
set fish_greeting

# set the fish history pager mode to 'prefix' for better history navigation
set -U fish_history_pager_mode prefix

# Load local config if exists
if test -e "$HOME/.config/fish/config.local.fish"
  source "$HOME/.config/fish/config.local.fish"
end

# Cleanup
# ------------------------------------------------------------------------------
# unset GEM_HOME set by tmuxinator
# see: https://github.com/Homebrew/homebrew-core/issues/59484
#      https://discourse.brew.sh/t/why-does-tmuxinator-sets-gem-home/7296
if set -q GEM_HOME; set -Ue GEM_HOME; end
