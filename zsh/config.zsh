#
# User Configuration
# -----------------------------------------------------------------------------

# Add custom (local) bins to $PATH
export PATH="$PATH:$HOME/.bin"

# Add homebrew bins to $PATH
export PATH=/usr/local/bin:/opt/homebrew/bin:$PATH

# Add GO bins to $PATH
export PATH="$PATH:$HOME/go/bin"

# export MANPATH="/usr/local/man:$MANPATH"

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='nvim'

  alias oldvim=$(which vim)
  alias vim=nvim
fi

# Load zsh completions
if type brew &>/dev/null; then
  FPATH=$(brew --prefix)/share/zsh-completions:$FPATH

  autoload -Uz compinit
  compinit
fi

export RUBYOPT="-W0"

# Init rbenv
eval "$(rbenv init -)"

# load pyenv
if command -v pyenv 1>/dev/null 2>&1; then
  eval "$(pyenv init -)"

  # Add python binaries to $PATH
  export PATH="$PATH:$(pyenv root)/shims"
fi

# Load nvm
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# take .nvmrc files into account
autoload -U add-zsh-hook
load-nvmrc() {
  local node_version="$(nvm version)"
  local nvmrc_path="$(nvm_find_nvmrc)"

  if [ -n "$nvmrc_path" ]; then
    local nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")")

    if [ "$nvmrc_node_version" = "N/A" ]; then
      nvm install
    elif [ "$nvmrc_node_version" != "$node_version" ]; then
      nvm use
    fi
  elif [ "$node_version" != "$(nvm version default)" ]; then
    echo "Reverting to nvm default version"
    nvm use default
  fi
}
add-zsh-hook chpwd load-nvmrc
load-nvmrc

# Add keyboard things (mdloader_mac & QMK firmare) to $PATH
export PATH="$PATH:$HOME/Code/keyboards/mdloader/build"

# Add mongoDB.app binaries to path
export PATH="/Applications/MongoDB.app/Contents/Resources/Vendor/mongodb/bin:$PATH"

# export QMK_HOME="/Users/jdurand/Code/keyboards/massdrop-alt"
export QMK_HOME="/Users/jdurand/Code/keyboards/qmk_firmware"
export QMK_FIRMWARE="/Users/jdurand/Code/keyboards/qmk_firmware"
# export QMK_FIRMWARE="/Users/jdurand/qmk_firmware"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be elaced here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# Simplify tmuxinator invocation
alias mux=tmuxinator

# Lazy alias for lazygit
alias ggit=lazygit

# alias func='ghprs'
# function gitprs() {
#   'gh pr list --search "status:success" --draft=false'
# }

# Use meld as git mergetool
alias meld=/Applications/Meld.app/Contents/MacOS/Meld

# use Ag instead of Ack
alias ack=ag

# add openssl v1.1 to PATH
export PATH="/opt/homebrew/opt/openssl@1.1/bin:$PATH"
# For compilers to find openssl@1.1
export LDFLAGS="-L/opt/homebrew/opt/openssl@1.1/lib"
export CPPFLAGS="-I/opt/homebrew/opt/openssl@1.1/include"
# For pkg-config to find openssl@1.1
export PKG_CONFIG_PATH="/opt/homebrew/opt/openssl@1.1/lib/pkgconfig"

# export PATH="/usr/local/opt/openssl@1.1/bin:$PATH"
# # For compilers to find openssl@1.1
# export LDFLAGS="-L/usr/local/opt/openssl@1.1/lib"
# export CPPFLAGS="-I/usr/local/opt/openssl@1.1/include"
# # For pkg-config to find openssl@1.1
# export PKG_CONFIG_PATH="/usr/local/opt/openssl@1.1/lib/pkgconfig"

# Add Android SDK to PATH
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/platform-tools

export CONDA_AUTO_ACTIVATE_BASE=false

# Increaase opened file limit
ulimit -n 2048

