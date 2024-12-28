
" Easy new lines
" ----------------------------------------------------------------------------------------------------
noremap <silent> ø mo<Esc>o<Esc>k`o
noremap <silent> Ø mo<Esc>O<Esc>j`o
noremap K <Esc>i<CR><Esc><Esc>

" Save with CTRL-S
" ----------------------------------------------------------------------------------------------------
noremap <silent> <C-S> :update<CR>
vnoremap <silent> <C-S> <C-C>:update<CR>
inoremap <silent> <C-S> <C-O>:update<CR>

" Always go to the mark’s line and column
" ----------------------------------------------------------------------------------------------------
nmap ' `
vmap ' `
noremap g' g`
vnoremap g' g`

" Remap ^ caracters
" ----------------------------------------------------------------------------------------------------
nmap â ^a
nmap î ^i
nmap ô ^o

" Add a new Text Objects
" ----------------------------------------------------------------------------------------------------
omap i/ :normal T/vt/<CR>
vmap i/ t/oT/
omap a/ :normal F/vf/<CR>
vmap a/ f/oF/
omap i\| :normal T\|vt\|<CR>
vmap i\| t\|oT\|
omap a\| :normal F\|vf\|<CR>
vmap a\| f\|oF\|

" Remap Enter and Backspace
" ----------------------------------------------------------------------------------------------------
vmap  <NOP>
vmap <BS> dk$

" Easy line moving
" ----------------------------------------------------------------------------------------------------
nmap <silent> ∆ ddp
nmap <silent> ˚ ddkkp
vmap <silent> ∆ djPV`]
vmap <silent> ˚ dkPV`]

" Select only the text caracters in the current line
" ----------------------------------------------------------------------------------------------------
nmap √ ^v$h

" Easy indentation in visual mode
" ----------------------------------------------------------------------------------------------------
vnoremap < <gv
vnoremap > >gv|
vnoremap <Tab> >gv|
vnoremap <S-Tab> <gv
nnoremap  <C-i>
nnoremap <Tab> mzV>`zl
nnoremap <S-Tab> mzV<`zh

" Clear search-highlighted terms and dismiss Noice messages
" ----------------------------------------------------------------------------------------------------
nmap <silent> \ :silent noh<Bar>echo<Bar>NoiceDismiss<CR>

" Use Alt-4 to go to the end of the line, but not totally.
" ----------------------------------------------------------------------------------------------------
vmap ¢ $h

" ----------------------------------------------------------------------------------------------------
" Search and replace visually selected text
vnoremap <C-r> "hy:%s/<C-r>h//g<left><left>

nnoremap <C-c> :bp\|bd #<CR>
nnoremap <Leader>= :vsplit<CR><C-w>l
nnoremap <Leader>l :vsplit<CR><C-w>l
nnoremap <Leader>- :split<CR><C-w>j
nnoremap <Leader>j :split<CR><C-w>j

nnoremap <C-]> :tag <c-r><c-w><cr>
