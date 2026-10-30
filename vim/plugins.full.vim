" Full mode plugins (loaded in addition to plugins.light.vim).
" Add your own here. After editing, run ./install.sh (or :PlugInstall in vim).

" Navigation / search (uses fzf + ripgrep binaries; install with ./install.sh --full --deps)
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'

" Git
Plug 'tpope/vim-fugitive'     " :Git blame, :Git diff, ...
Plug 'airblade/vim-gitgutter' " +/-/~ markers in the sign column

" Languages: syntax for ~600 languages incl. Verilog/SystemVerilog, C/C++, Python
Plug 'sheerun/vim-polyglot'

" Looks
Plug 'itchyny/lightline.vim'  " Light status bar
Plug 'morhetz/gruvbox'        " Colorscheme
