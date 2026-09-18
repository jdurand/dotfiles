<!-- # dotfiles -->

# .dotfiles

## Usage

Review these files and selectively copy relevant parts to get a good understanding of
how your own CLI behaves. You can use these files as they are, but be aware system
differences to my own may cause issues. Adapt and fork them to suit your needs.

## Setup

To streamline the installation process, run the `./setup` script. This script will:
- Set up packages, terminal fonts and development tools
- Optionally install SketchyBar along with its dependencies
- Create or correct configuration symlinks, backing up conflicting local configs

On Arch Linux, the script installs `rust`, `fish`, and `fisher` with Pacman.
On Omarchy, it links the tracked Hyprland files plus Omarchy hooks, extensions,
and branding files while leaving theme-managed directories local.
It also installs `kanata` and configures the Apple MTP keyboard to send Escape
when Caps Lock is tapped and Control when it is held.

### Optional Features

You can pass additional options to the setup script to install optional features:

- `+sketchybar`: Installs SketchyBar and its dependencies.

### Example Usage

```sh
curl -L https://raw.githubusercontent.com/jdurand/dotfiles/refs/heads/main/_setup/install-dotfiles -o /tmp/setup-jdurand-dotfiles.bash && \
  bash /tmp/setup-jdurand-dotfiles.bash [+sketchybar]
```
