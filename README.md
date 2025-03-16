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
- Create symlinks for configuration files

### Optional Features

You can pass additional options to the setup script to install optional features:

- `+sketchybar`: Installs SketchyBar and its dependencies.

### Example Usage

```sh
curl -L https://raw.githubusercontent.com/jdurand/dotfiles/refs/heads/main/_setup/install-dotfiles -o /tmp/setup-jdurand-dotfiles.bash && \
  bash /tmp/setup-jdurand-dotfiles.bash [+sketchybar]
```
