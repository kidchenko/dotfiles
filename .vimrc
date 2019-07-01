" the basics
syntax enable
set nocompatible
set encoding=utf-8

" windows clipboard integration
set clipboard=unnamed

" intelligent searching and formatting
set ignorecase
set smartcase
set smartindent
set smarttab

" modern rendering
set renderoptions=type:directx
set incsearch
set lazyredraw
set ttyfast

" tab
set tabstop=4
set shiftwidth=4
set expandtab
set nowrap

" better parenthesis / html tag matching
runtime! macros/matchit.vim

filetype off                  " required

" Vundle
" set the runtime path to include Vundle and initialize
set rtp+=$HOME/.vim/bundle/Vundle.vim/
call vundle#begin('$HOME/.vim/bundle/')

Plugin 'VundleVim/Vundle.vim'
Plugin 'tpope/vim-fugitive'
Plugin 'git://git.wincent.com/command-t.git'
Plugin 'rstacruz/sparkup', {'rtp': 'vim'}
Plugin 'matchit.zip'
Plugin 'chiel92/vim-autoformat'
Plugin 'mattn/emmet-vim'
Plugin 'tpope/vim-surround'
call vundle#end()            " required

filetype plugin indent on    " required
"standard vim options
set guifont=Consolas:h14:cANSI
set backspace=indent,eol,start
set guioptions-=T
syntax enable
set tabstop=4
set shiftwidth=4
set expandtab
set ignorecase
set smartcase
set smarttab
set smartindent
set wildmenu
set incsearch
set lazyredraw
set ttyfast
set nowrap
set t_Co=256
set visualbell
set visualbell t_vb=
set encoding=utf-8
set clipboard=unnamed
set ruler
set number
set relativenumber
set ofu=syntaxcomplete#Complete
set laststatus=2
set listchars=tab:>\ ,trail:-,extends:>,precedes:<,nbsp:+
set formatoptions+=j " Delete comment character when joining commented lines
filetype plugin indent on
colorscheme desert
set noswapfile
"autocmd FileType xml let g:formatprg_args_expr_xml .= '." --indent-attributes 1"'
"https://vi.stackexchange.com/a/7268
let g:formatdef_fmt_custom_xml = '"tidy -xml -q --show-errors 0 --show-warnings 0 --indent-attributes 1 --indent 1 --indent-spaces 4 --indent-cdata 1 --vertical-space 0 --show-body-only 1"'
let g:formatters_xml = ['fmt_custom_xml']