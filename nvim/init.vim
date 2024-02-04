set runtimepath^=~/.vim runtimepath+=~/.vim/after
let &packpath=&runtimepath

" Define the leader key
" ----------------------------------------------------------------------------------------------------
let mapleader = ";"
let g:mapleader = ";"

lua require('dependencies')

source ~/.vimrc

lua require('user.keymaps')
lua require('user.settings')
