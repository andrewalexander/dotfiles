set nocompatible
syntax enable
let g:rehash256 = 1

set t_Co=256
filetype off
filetype plugin indent on
set noshowcmd noruler

set ttyfast
set ttymouse=xterm2
set ttyscroll=3

set laststatus=2
set encoding=utf-8              " Set default encoding to UTF-8
set autoread                    " Automatically reread changed files without asking me anything
set autoindent
set backspace=indent,eol,start  " Makes backspace key more powerful.
set incsearch                   " Shows the match while typing
set hlsearch                    " Highlight found searches
set mouse=a

if has('persistent_undo')
  set undofile
  set undodir=$HOME/.vim/undo
  set undolevels=1000
  set undoreload=10000
endif

if !empty(glob("$HOME/.vimrc.local"))
    source $HOME/.vimrc.local
endif
set directory=$HOME/.vim/swap/

set noerrorbells             " No beeps
set number                   " Show line numbers
set showcmd                  " Show me what I'm typing
set nobackup                 " Don't create annoying backup files TODO: this might not do anything
set backupcopy=no            " Prevent backups and creation of 4913 file
set splitright               " Split vertical windows right to the current windows
set splitbelow               " Split horizontal windows below to the current windows
set autowrite                " Automatically save before :next, :make etc.
set hidden
set fileformats=unix,dos,mac " Prefer Unix over Windows over OS 9 formats
set noshowmatch              " Do not show matching brackets by flickering
set noshowmode               " We show the mode with airline or lightline
set ignorecase               " Search case insensitive...
set smartcase                " ... but not if it begins with upper case
set completeopt=menu,menuone
set nocursorcolumn           " speed up syntax highlighting
set nocursorline
set updatetime=400
set pumheight=10             " Completion window max size
set lazyredraw               " Wait to redraw
set noswapfile
set clipboard=unnamedplus
"set foldenable
"set foldlevelstart=10
"set foldnestmax=10
"set foldmethod=expr
"set foldexpr=RFoldexpr(v:lnum)
"function! RFoldexpr(lnum)
  "if getline(a:lnum) =~ '^\("\|#\)\+\s\+=========.* SECTION$'
	"" Start a new level-one fold
	"return '>1'
  "else
	"" Use the same foldlevel as the previous line
	"return '='
  "endif
"endfunction


" Automatically resize vim when terminal window changes
autocmd VimResized * wincmd =
