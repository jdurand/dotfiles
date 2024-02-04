# dotfiles

## Installation

```sh
cd ~
git@github.com:jdurand/dotfiles.git .dotfiles
ln -s ~/.dotfiles/tmux .tmux
ln -s ~/.tmux/tmux.conf .tmux.conf

ln -s ~/.dotfiles/vim .vim
ln -s ~ /.dotfiles/vim/vimrc .vimrc

cd .config
ln -s ~/.dotfiles/alacritty
ln -s ~/.dotfiles/nvim
ln -s ~/.dotfiles/powerline
ln -s ~/.dotfiles/tmuxinator
```
