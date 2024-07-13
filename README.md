<!-- # dotfiles -->

# .dotfiles

## Usage

Review these files and selectively copy relevant parts to get a good understanding of
how your own CLI behaves. You can use these files as they are, but be aware system
differences to my own may cause issues. Adapt and fork them to suit your needs.

## Setup

To streamline the installation process, run the `./setup` script. This script will:
- Install Oh My Zsh
- Install Powerlevel10k
- Install necessary dependencies for Tmux Tokyo Night Theme
- Setup symlinks for all configurations

```sh
if [ ! -d "$HOME/.dotfiles" ]; then; git clone https://github.com/jdurand/dotfiles.git "$HOME/.dotfiles"; fi; bash "$HOME/.dotfiles/setup"
```
