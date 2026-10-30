" ~/.vimrc - shared by light and full mode.
" Mode comes from ~/.dotfiles_mode (written by install.sh).
"   Light: this file + vim/plugins.light.vim
"   Full:  also vim/plugins.full.vim and vim/full.vim (your custom stuff)

set nocompatible            " Use Vim defaults instead of old vi behavior (must be first)

" --- Mode -----------------------------------------------------------------
let g:dotfiles_mode = 'light'
if filereadable(expand('~/.dotfiles_mode'))
  let s:m = readfile(expand('~/.dotfiles_mode'))
  if len(s:m) && s:m[0] =~# 'full' | let g:dotfiles_mode = 'full' | endif
endif
let g:dotfiles_dir = expand('~/.dotfiles')

" --- Plugins (vim-plug) ---------------------------------------------------
if filereadable(expand('~/.vim/autoload/plug.vim'))
  call plug#begin('~/.vim/plugged')
  execute 'source' g:dotfiles_dir . '/vim/plugins.light.vim'
  if g:dotfiles_mode ==# 'full'
    execute 'source' g:dotfiles_dir . '/vim/plugins.full.vim'
  endif
  call plug#end()           " also runs: filetype plugin indent on, syntax enable
endif

" --- Base settings (both modes) -------------------------------------------
filetype plugin indent on   " Load per-language plugins and indentation
syntax enable               " Syntax highlighting
set hidden                  " Switch buffers without saving first
set shortmess+=I            " No intro screen on startup
set number                  " Line numbers
set hlsearch                " Highlight all search matches
set incsearch               " Jump to matches while typing the search
set ignorecase smartcase    " Case-insensitive search unless you type a capital
set backspace=indent,eol,start
set encoding=utf-8

" --- Full mode extras -------------------------------------------------------
if g:dotfiles_mode ==# 'full' && filereadable(g:dotfiles_dir . '/vim/full.vim')
  execute 'source' g:dotfiles_dir . '/vim/full.vim'
endif

" Per-machine tweaks (untracked)
if filereadable(expand('~/.vimrc.local')) | source ~/.vimrc.local | endif
