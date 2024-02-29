" Set local directory based on Neovim presence
" ----------------------------------------------------------------------------------------------------

if has('nvim')
  let s:vimlocal=$HOME.'/.nvim-local'
else
  let s:vimlocal=$HOME.'/.vim-local'
endif

" Activate syntax highlighting
" ----------------------------------------------------------------------------------------------------
syntax on

" Window title
" ----------------------------------------------------------------------------------------------------
let &titlestring = hostname()
set title

" Activate filetype plugins
" ----------------------------------------------------------------------------------------------------
filetype on
filetype plugin indent on
filetype indent on

" Disable netrw
" ----------------------------------------------------------------------------------------------------
let g:loaded_netrw = 1
let g:loaded_netrwPlugin = 1

" Activate folds
" ----------------------------------------------------------------------------------------------------
set foldmethod=marker

" noremap <Space> <nop>
" sunmap <Space>

" let mapleader = "\<Space>"
" let g:mapleader = "\<Space>"

" Misc. options
" ----------------------------------------------------------------------------------------------------
set showcmd " Display the command as we type it
set showmode " Display the current mode
set ignorecase " Ignore case when searching
set smartcase " Smart-case search mode
set incsearch " Start to search as soon as we type
set mouse= " Never use the mouse
set number " Show line numbers
set ts=2 " A tab = 4 spaces
set sw=2 " Shift width
set sts=2 " Short tab stop
set et " Use spaces instead of tabs
set whichwrap=h,l,~,[,],<,> " Which caracters to wrap
set scrolloff=4 " Scroll offset
set laststatus=2 " Always show the status line
set noautoread " Do not reload the file if it changes
set title " Display filename in window title
set showmatch " Show matching parentheses
set noautoindent " Code auto-indent
set nosmartindent " Smart code auto-indent
set cindent " Use C-style indent
" set showtabline=0 " Always hide tabs
set hlsearch " Highlight matching search result
set vb t_vb= " No visual bell
set mls=10 " Check for modelines in the first and last 10 lines
set noeol
set wildmenu
set wildmode=full
" set switchbuf=usetab,newtab " split|newtab
set switchbuf=split
set backspace=indent,eol,start
set tabpagemax=50
set isk+=- " Treat “-” like a word separator (for auto-completion!)
set isk+=? " Treat “?” like a word separator (for auto-completion!)
set isk+=! " Treat “!” like a word separator (for auto-completion!)
set hidden " Allow hidden buffers
set gdefault " Always search/replace globally
set shell=zsh
set clipboard=unnamedplus " Make sure we can copy-paste into the system clipboard
set nostartofline
set lazyredraw " Do not redraw screen in non-essential situations
set shortmess=A

" Viminfo
" ----------------------------------------------------------------------------------------------------
execute "set viminfo=".'''50,<1000,s100,h,n'.s:vimlocal.'/info'

" Always use UTF-8
" ----------------------------------------------------------------------------------------------------
if !has('nvim')
  set encoding=utf-8
  set fileencoding=utf-8
end

" Backups
" ----------------------------------------------------------------------------------------------------
set backup
set swapfile

execute "set backupdir=".s:vimlocal.'/backup'
execute "set directory=".s:vimlocal.'/swap'

if exists("+undofile")
  set undofile
  execute "set undodir=".s:vimlocal.'/undo'
endif

" No automatic word-wrap!
" ----------------------------------------------------------------------------------------------------
set nowrap
set sidescroll=4
set sidescrolloff=14
set listchars=precedes:←,extends:→,nbsp:◊,trail:⠿,eol:\ ,tab:●·
set list

" We often press 'Shift' when we should not
" ----------------------------------------------------------------------------------------------------
command! -nargs=* -bang -complete=file Q q <args>
command! -nargs=* -bang -complete=file W w <args>
command! -nargs=* -bang -complete=file Wq wq <args>
command! -nargs=* -bang -complete=file WQ wq <args>
command! -nargs=* -bang -complete=file E e <args>
command! -nargs=* -complete=file Cd cd <args>
command! -nargs=* -complete=file CD cd <args>

" Statusline
" ----------------------------------------------------------------------------------------------------
function! IsHelp()
  return &buftype=='help'?' (help) ':''
endfunction

function! GetName()
  return expand("%:t")==''?'<none>':substitute(expand("%:p"), getcwd() . "/", "", "g")
endfunction

set statusline=%1*\ %{GetName()}\ %3*
set statusline+=%7*%{&modified?'\ (modified)':'\ '}%3*
set statusline+=%5*%{IsHelp()}%3*
set statusline+=%6*%{&readonly?'\ (read-only)\ ':'\ '}%3*
set statusline+=%3*fenc:%4*%{strlen(&fenc)?&fenc:'none'}%3*\ \ 
set statusline+=%3*ff:%4*%{&ff}%3*\ \ 
set statusline+=%3*ft:%4*%{strlen(&ft)?&ft:'<none>'}\ \ 
set statusline+=%3*tab:%4*%{&ts}
set statusline+=%3*,%4*%{&sts}
set statusline+=%3*,%4*%{&sw}
set statusline+=%3*,%4*%{&et?'et':'noet'}\ \ 
set statusline+=%<%3*pwd:%4*%{getcwd()}\ \ 
set statusline+=%3*%=
set statusline+=%3*col:%4*%c\ \ 
set statusline+=%3*line:%4*%l\ \ 
set statusline+=%3*total:%4*%L\ 

" Mark trailing whitespace
" ----------------------------------------------------------------------------------------------------
match Todo /\(\(\t\|\s\)\+$\)/

" Locale
" ----------------------------------------------------------------------------------------------------
let $LC_ALL = "fr_CA.UTF-8"

" Airline customization
"
" hide default mode... it's displayed in the status line
" set noshowmode

" " fix for tmux glitch: change status on tmux
" if strlen($TMUX) " skip if we're not in a tmux session
"   " https://github.com/edkolev/tmuxline.vim/issues/24
"   function! AddTmuxlineStatus()
"     if exists(':Tmuxline')
"       augroup airline_tmuxline
"         au!
"         au InsertEnter * call SetInsert()
"         autocmd InsertLeave * call SetNormal()
"         vnoremap <silent> <expr> <SID>SetVisual SetVisual()
"         nnoremap <silent> <script> v v<SID>SetVisual
"         nnoremap <silent> <script> V V<SID>SetVisual
"         nnorema <silent> <script> <C-v> <C-v><SID>SetVisual
"         autocmd CursorHold * call SetNormal()
"       augroup END
"     endif
"   endfunction
"   function! SetInsert()
"     if v:insertmode == 'i'
"       Tmuxline airline_insert
"     else
"       Tmuxline airline_replace
"     endif
"   endfunction
"   function! SetVisual()
"     set updatetime=0
"     Tmuxline airline_visual
"     return 'lh'
"   endfunction
"   function! SetNormal()
"     set updatetime=4000
"     Tmuxline airline
"   endfunction
"   au VimEnter * :call AddTmuxlineStatus()
" endif
