#
# Variables
# -----------------------------------------------------------------------------

# Add custom (local) bins to $PATH
export PATH="$PATH:$HOME/.local/bin"

# Add homebrew bins to $PATH
if [[ "$OSTYPE" == "darwin"* ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
  if [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    # Keep Linuxbrew after system paths (/usr/bin) so brew formulas (e.g. dbus/systemd)
    # don't shadow native system binaries.
    PATH="${PATH//\/home\/linuxbrew\/.linuxbrew\/bin:/}"
    PATH="${PATH//\/home\/linuxbrew\/.linuxbrew\/sbin:/}"
    export PATH="$PATH:/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin"
  fi
else
  eval "$(brew shellenv)"
fi

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

export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"

# .NET / C# (homebrew dotnet)
if [[ -d "/opt/homebrew/opt/dotnet/libexec" ]]; then
  export DOTNET_ROOT="/opt/homebrew/opt/dotnet/libexec"
  export PATH="$DOTNET_ROOT:$PATH"
fi

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

# Set environment variables for Rails with Puma in clustered mode.
# OBJC_DISABLE_INITIALIZE_FORK_SAFETY: Disables the Objective-C runtime's safety checks when forking processes,
# allowing better compatibility with multi-threaded servers like Puma.
export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES
# PGGSSENCMODE: Disables GSSAPI encryption for PostgreSQL connections,
# which can help prevent authentication issues in clustered environments.
export PGGSSENCMODE=disable

# Silence direnv loading messages (errors/blocked notices still show)
export DIRENV_LOG_FORMAT=""

# qlty
export QLTY_INSTALL="$HOME/.qlty"
export PATH="$QLTY_INSTALL/bin:$PATH"
