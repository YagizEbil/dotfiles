" Full mode settings - put your custom Vim stuff here.
" Sourced at the end of ~/.vimrc when ~/.dotfiles_mode is 'full'.

let mapleader = ' '

" --- Editing ---------------------------------------------------------------
set relativenumber          " Relative numbers (with 'number' = hybrid)
set mouse=a                 " Mouse support
set scrolloff=5             " Keep context around the cursor
set expandtab shiftwidth=4 tabstop=4 softtabstop=4
set splitright splitbelow
set updatetime=300          " Faster gitgutter updates
set signcolumn=yes
if has('clipboard') | set clipboard^=unnamed,unnamedplus | endif

" Persistent undo
if has('persistent_undo')
  let s:undo = expand('~/.vim/undo')
  if !isdirectory(s:undo) | call mkdir(s:undo, 'p') | endif
  let &undodir = s:undo
  set undofile
endif

" --- Looks -----------------------------------------------------------------
set background=dark
if has('termguicolors') && $COLORTERM =~# 'truecolor\|24bit' | set termguicolors | endif
silent! colorscheme gruvbox
set laststatus=2 noshowmode
let g:lightline = { 'colorscheme': 'gruvbox' }

" --- Mappings ---------------------------------------------------------------
nnoremap <leader>f :Files<CR>
nnoremap <leader>b :Buffers<CR>
nnoremap <leader>g :Rg<CR>
nnoremap <leader>h :nohlsearch<CR>
nnoremap <leader>w :w<CR>
