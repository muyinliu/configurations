colorscheme delek

set number
"show line numbers

nnoremap <C-L> :set nonumber!<CR>
"Toggle line numbers

nnoremap <C-P> :set paste<CR>
"Toggle paste state

nnoremap <C-T> :tabnew<CR>
"New Tab

syntax on

set tabstop=4
set expandtab

set smartindent
set autoindent
set shiftwidth=4
set cindent

set showmatch

set display=lastline

set ignorecase
set smartcase

filetype on
filetype indent on
filetype plugin on
filetype plugin indent on

set hlsearch
set incsearch

set laststatus=2

set backspace=2
