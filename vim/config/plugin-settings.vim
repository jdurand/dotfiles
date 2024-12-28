
" YankRing
" ----------------------------------------------------------------------------------------------------
let g:yankring_history_dir = expand('$HOME').'/.vim-local'
let g:yankring_history_file = '.vim-yankring'
map <Leader>y :YRShow<CR>
autocmd BufEnter \[YankRing\] set scrolloff=0 cursorline
autocmd BufLeave \[YankRing\] set scrolloff=4 nocursorline
let g:yankring_clipboard_monitor=0

" Rails.vim settings
" ----------------------------------------------------------------------------------------------------
let g:rails_statusline=0

" Ack.vim settings
" ----------------------------------------------------------------------------------------------------
let g:ackprg = 'rg --no-heading --color=never --column --line-number'

" vim-markdown settings
" ----------------------------------------------------------------------------------------------------
let g:vim_markdown_folding_disabled=1

" vim-localvimrc settings
" ----------------------------------------------------------------------------------------------------
let g:localvimrc_name = [".local.vimrc"]
let g:localvimrc_persistent = 1
let g:localvimrc_persistence_file = expand('$HOME').'/.vim-local/vim-localvimrc'

" vim-javascript settings
" ----------------------------------------------------------------------------------------------------
let b:javascript_fold=0
let g:javascript_plugin_flow=1
hi! def link jsGlobalObjects Conditional
hi! def link jsStatement Statement
hi! def link jsConditional Statement
hi! def link jsRepeat Statement
hi! def link jsLabel Statement
hi! def link jsKeyword Statement
hi! def link jsClass Statement
hi! def link jsException Statement
hi! def link jsSuper Statement
hi! def link jsStorageClass Statement
hi! def link jsPrototype Statement
hi! def link jsThis Identifier

" vim-jsx settings
" ----------------------------------------------------------------------------------------------------
let g:jsx_ext_required = 0
