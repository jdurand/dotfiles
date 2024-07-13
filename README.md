<!-- # dotfiles -->

## Installation

#### Install Oh My Zsh
```sh
ZSH=~/.dotfiles/vendor/oh-my-zsh sh -c "$(curl -fsSL https://install.ohmyz.sh/)"
```

#### Install Oh My Posh
```sh
brew install jandedobbeleer/oh-my-posh/oh-my-posh
```

#### Setup Symlinks
```sh
cd ~
git@github.com:jdurand/dotfiles.git .dotfiles

ln -s ~/.dotfiles/zsh .zsh
ln -s ~/.zsh/zshrc .zshrc

ln -s ~/.dotfiles/tmux .tmux
ln -s ~/.tmux/tmux.conf .tmux.conf

ln -s ~/.dotfiles/vim .vim
ln -s ~/.vim/vimrc .vimrc

ln -s ~/.dotfiles/fzf/fzf.zsh .fzf.zsh
ln -s ~/.dotfiles/fzf .fzf

cd .config
ln -s ~/.dotfiles/alacritty
ln -s ~/.dotfiles/nvim
ln -s ~/.dotfiles/powerline
ln -s ~/.dotfiles/tmuxinator
ln -s ~/.dotfiles/kitty
```
