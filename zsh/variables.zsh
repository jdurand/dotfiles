#
# Variables
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

# Lazygit config file
# (defaults to ~/Library/Application\Support/lazygit on MacOS)
export LG_CONFIG_FILE="$HOME/.config/lazygit/config.yml"

# Add keyboard things (mdloader_mac & QMK firmare) to $PATH
export PATH="$PATH:$HOME/Code/keyboards/mdloader/build"

# Add mongoDB.app binaries to path
export PATH="/Applications/MongoDB.app/Contents/Resources/Vendor/mongodb/bin:$PATH"

# export QMK_HOME="$HOME/Code/keyboards/massdrop-alt"
export QMK_HOME="$HOME/Code/keyboards/qmk_firmware"
export QMK_FIRMWARE="$HOME/Code/keyboards/qmk_firmware"
# export QMK_FIRMWARE="$HOME/qmk_firmware"

# MacOS executables
if [[ "$OSTYPE" == "darwin"* ]]; then
  # Add Alacritty to PATH from the command line if not already defined
  if [[ -z "$(command -v alacritty)" ]]; then
    export PATH="/Applications/Alacritty.app/Contents/MacOS:$PATH"
  fi
fi

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

# Timezone
export TZ="America/Montreal"

# History limits
export HISTFILE=$HOME/.zhistory
export HISTSIZE=1000000
export SAVEHIST=1000000

# Locales
export LANG="en_US.UTF-8"
export LC_ALL=$LANG

# Replace cat with bat
alias cat='bat --paging=never'

# Use bat as a colorizing pager for man
export MANPAGER="sh -c 'col -bx | bat -l man -p'"
