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

# Load all environment configuration files
if test -d ~/.dotfiles/environment
  for env_file in ~/.dotfiles/environment/*.env
    if test -f $env_file
      for line in (cat $env_file | grep -v '^#' | grep -v '^$')
        # Remove 'export ' prefix if present
        set clean_line (echo $line | sed 's/^export //')
        set var_name (echo $clean_line | cut -d= -f1)
        set var_value (echo $clean_line | cut -d= -f2- | sed 's/^"//;s/"$//')
        # Only set if var_name is valid (contains only letters, numbers, underscores)
        if echo $var_name | grep -q '^[A-Za-z_][A-Za-z0-9_]*$'
          set -x $var_name $var_value
        end
      end
    end
  end
end

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
function get_brew_prefix
  if test -e /opt/homebrew/bin/brew
    echo /opt/homebrew
  else if test -e /home/linuxbrew/.linuxbrew/bin/brew
    echo /home/linuxbrew/.linuxbrew
  else if test -e /usr/local/bin/brew
    echo /usr/local
  else if command -q brew
    brew --prefix
  else
    return 1
  end
end

set brew_prefix (get_brew_prefix)

if test -n "$brew_prefix"
  $brew_prefix/bin/brew shellenv | source
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

# Ensure fisher is available and plugins are loaded in interactive mode
if status is-interactive
  # Load fisher if not already available
  if not functions -q fisher; and test -f $brew_prefix/share/fish/vendor_functions.d/fisher.fish
    source $brew_prefix/share/fish/vendor_functions.d/fisher.fish
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
alias top='btop'
# alias claude="$HOME/.claude/local/claude"

# Keybindings
# ------------------------------------------------------------------------------

# git.fzf.fish
if type -q setup_git_fzf_key_bindings
  setup_git_fzf_key_bindings
end

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

# Run startup script
if test -e "$HOME/.dotfiles/fish/startup.fish"
  if test -z "$TMUX" -a -z "$NVIM"
    if status is-interactive
      source "$HOME/.dotfiles/fish/startup.fish"
    end
  end
end
