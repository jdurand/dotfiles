#
# Variables and Aliases
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
  alias vi=nvim
  alias v=nvim
fi

export RUBYOPT="-W0"

# Add keyboard things (mdloader_mac & QMK firmare) to $PATH
export PATH="$PATH:$HOME/Code/keyboards/mdloader/build"

# Add mongoDB.app binaries to path
export PATH="/Applications/MongoDB.app/Contents/Resources/Vendor/mongodb/bin:$PATH"

# export QMK_HOME="/Users/jdurand/Code/keyboards/massdrop-alt"
export QMK_HOME="/Users/jdurand/Code/keyboards/qmk_firmware"
export QMK_FIRMWARE="/Users/jdurand/Code/keyboards/qmk_firmware"
# export QMK_FIRMWARE="/Users/jdurand/qmk_firmware"

# Simplify tmuxinator invocation
alias mux=tmuxinator

# Lazy alias for lazygit
alias ggit=lazygit

# alias func='ghprs'
# function gitprs() {
#   'gh pr list --search "status:success" --draft=false'
# }

# MacOS executables
if [[ "$OSTYPE" == "darwin"* ]]; then
  # Use meld as git mergetool if not already defined
  if [[ -z "$(command -v meld)" ]]; then
    alias meld=/Applications/Meld.app/Contents/MacOS/Meld
  fi

  # Add Alacritty to PATH from the command line if not already defined
  if [[ -z "$(command -v alacritty)" ]]; then
    export PATH="/Applications/Alacritty.app/Contents/MacOS:$PATH"
  fi
fi

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

# Disable Touchbar git buttons
TOUCHBAR_GIT_ENABLED=false

# Increaase opened file limit
ulimit -n 2048
