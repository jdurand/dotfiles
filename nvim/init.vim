set runtimepath^=~/.vim runtimepath+=~/.vim/after
let &packpath=&runtimepath

" Define the leader key
" ----------------------------------------------------------------------------------------------------
let mapleader = ";"
let g:mapleader = ";"

lua require('plugins')

source ~/.vimrc

lua require('config')
