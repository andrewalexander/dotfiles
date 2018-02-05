" ==================== Settings ==================== SECTION
set nocompatible
syntax enable
let g:rehash256 = 1
colorscheme molokai_dark
set t_Co=256
filetype off
filetype plugin indent on

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
set nobackup                 " Don't create annoying backup files
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
set foldenable
set foldlevelstart=10
set foldnestmax=10
set foldmethod=expr
set foldexpr=RFoldexpr(v:lnum)
function! RFoldexpr(lnum)
  if getline(a:lnum) =~ '^\("\|#\)\+\s\+=========.* SECTION$'
	" Start a new level-one fold
	return '>1'
  else
	" Use the same foldlevel as the previous line
	return '='
  endif
endfunction

" ==================== Mappings ==================== SECTION
"
let mapleader = ","

" Exit insert mode
imap jk <Esc>

" Easier menu access and remap repeat motion
nnoremap ; :
nnoremap m ;
nnoremap M ,,

" Standard Movement
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>
 
" Start/End Line Movement
nnoremap H ^
nnoremap L $
vnoremap H ^
vnoremap L $
 
" Move up and down on the same line when wraps
nnoremap j gj
nnoremap k gk
vnoremap j gj
vnoremap k gk

" Source (reload configuration)
nnoremap <silent> <F5> :source $MYVIMRC<CR>

" Edit vimrc in split
nnoremap <Leader>ev <C-w><C-v><C-l>:e $MYVIMRC<CR>
 
" Swap between buffers
nnoremap <C-g> :bnext<cr>
nnoremap <C-f> :bprev<cr>

" Redraw screen to remove highlighting
nnoremap <silent> <CR> :nohl<CR><CR>

" Split line
nnoremap S i<Enter><Esc>^

" Resize windows equally
nnoremap <Leader>w <C-w>=

" Toggle fold
nnoremap <space> za

" Reselect last visual selected lines (includes yank/paste)
nnoremap <silent> <leader>v `[v`]
vnoremap <silent> <leader>v v

" ==================== Plugins ==================== SECTION

call plug#begin('~/.vim/plugged')

Plug 'benmills/vimux'
Plug 'christoomey/vim-tmux-navigator'
Plug 'ConradIrwin/vim-bracketed-paste'
Plug 'ctrlpvim/ctrlp.vim'
Plug 'farmergreg/vim-lastplace'
Plug 'fatih/vim-go', { 'do': ':GoInstallBinaries'}
Plug 'honza/vim-snippets'
Plug 'itchyny/lightline.vim'
Plug 'scrooloose/nerdcommenter'
Plug 'scrooloose/nerdtree'
Plug 'tpope/vim-repeat'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-dispatch'
Plug 'Raimondi/delimitMate'
Plug 'SirVer/ultisnips'
Plug 'posva/vim-vue'
Plug 'rust-lang/rust.vim'

" Currently evaluating
Plug 'alvan/vim-closetag'
Plug 'derekwyatt/vim-fswitch'
Plug 'qpkorr/vim-bufkill'
Plug 'unblevable/quick-scope'

call plug#end()

" ==================== Plugins: Settings ==================== SECTION
" ==================== ctrlp ====================
let g:ctrlp_cmd = 'CtrlPMRU'
" ==================== quick-scope ====================
let g:qs_highlight_on_keys = ['f', 'F', 't', 'T']
" ==================== vim-bracketed-paste ====================
let g:bracketed_paste_tmux_wrap = 0
" ==================== Airline ====================
let g:lightline = {
      \ 'colorscheme': 'powerline',
      \ 'enable': {
      \   'statusline': 1,
      \   'tabline': 1
      \ },
      \ 'tabline': {
      \   'left': [ ['bufferline'] ]
      \ },
      \ 'component_expand': {
      \   'bufferline': 'LightlineBufferline',
      \ },
      \ 'component_type': {
      \   'bufferline': 'tabsel',
      \ },
      \ }

" ==================== NerdCommenter ====================
" <3 Yank, Comment, and Paste <3
nnoremap <silent> <Leader>cz yy:call NERDComment(1, "toggle")<CR>p
vnoremap <silent> <Leader>cz "yygv:call NERDComment(1, "toggle")<CR>`>p
" ==================== NerdTree ====================
let NERDTreeShowHidden=1
let g:NERDShutUp = 1
let NERDTreeIgnore = ['\.pyc$', '\.so$', '__pycache__$']
map <C-n> :NERDTreeToggle<CR>
noremap <Leader>f :NERDTreeFind<cr>
" ==================== fswitch ====================
autocmd! BufEnter *.cc let b:fswitchdst = 'h,hpp'
nnoremap <Leader>h :call FSwitch('%', '')<CR>
" ==================== vim-bufkill ====================
let g:BufKillActionWhenBufferDisplayedInAnotherWindow = 'kill'
noremap <silent> <Leader>bd :BD<cr>
" ==================== vim-go ====================
let g:go_fmt_fail_silently = 1
let g:go_fmt_command = "goimports"
let g:go_autodetect_gopath = 1
let g:go_list_type = "quickfix"
let g:go_auto_type_info = 0
let g:go_echo_command_info= 0
let g:go_highlight_extra_types = 0
let g:go_highlight_build_constraints = 1
let g:go_highlight_types = 1
let g:go_highlight_fields = 1
let g:go_highlight_functions = 1
let g:go_highlight_methods = 1
let g:go_highlight_operators = 1
augroup go
  autocmd!
  autocmd FileType go nmap <silent> <Leader>v <Plug>(go-def-vertical)
  autocmd FileType go nmap <silent> <Leader>s <Plug>(go-def-split)
  autocmd FileType go nmap <silent> <Leader>i <Plug>(go-info)
  autocmd FileType go nmap <silent> <Leader>l <Plug>(go-metalinter)
  autocmd FileType go nmap <silent> <leader>t  <Plug>(go-test)
  autocmd FileType go nmap <silent> <leader>gb  <Plug>(go-build)
  autocmd FileType go nmap <silent> <leader>gi  <Plug>(go-imports)
  autocmd FileType go nmap <silent> <leader>r  <Plug>(go-run)
  autocmd FileType go nmap <silent> <leader>e  <Plug>(go-install)
  autocmd FileType go nmap <silent> <Leader>d <Plug>(go-doc)
  autocmd FileType go nmap <silent> <Leader>c <Plug>(go-coverage-toggle)
  autocmd Filetype go command! -bang A call go#alternate#Switch(<bang>0, 'edit')
  autocmd Filetype go command! -bang AV call go#alternate#Switch(<bang>0, 'vsplit')
  autocmd Filetype go command! -bang AS call go#alternate#Switch(<bang>0, 'split')
  autocmd Filetype go command! -bang AT call go#alternate#Switch(<bang>0, 'tabe')
augroup END
" ==================== rust.vim ====================
let g:rustfmt_autosave = 1
" ==================== delimitMate ====================
let g:delimitMate_expand_cr = 1
let g:delimitMate_expand_space = 1
let g:delimitMate_smart_quotes = 1
let g:delimitMate_expand_inside_quotes = 0
let g:delimitMate_smart_matchpairs = '^\%(\w\|\$\)'
imap <expr> <CR> pumvisible() ? "\<c-y>" : "<Plug>delimitMateCR"
" ==================== vim-dispatch ====================
nnoremap <silent> <Leader>b :w<CR>:Make<cr>
" ==================== Vimux ====================
map <Leader>vp :VimuxPromptCommand<CR>
map <Leader>vl :VimuxRunLastCommand<CR>
" ==================== UltiSnips ====================
function! g:UltiSnips_Complete()
  call UltiSnips#ExpandSnippet()
  if g:ulti_expand_res == 0
    if pumvisible()
      return "\<C-n>"
    else
      call UltiSnips#JumpForwards()
      if g:ulti_jump_forwards_res == 0
        return "\<TAB>"
      endif
    endif
  endif
  return ""
endfunction

function! g:UltiSnips_Reverse()
  call UltiSnips#JumpBackwards()
  if g:ulti_jump_backwards_res == 0
    return "\<C-P>"
  endif

  return ""
endfunction


if !exists("g:UltiSnipsJumpForwardTrigger")
  let g:UltiSnipsJumpForwardTrigger = "<tab>"
endif

if !exists("g:UltiSnipsJumpBackwardTrigger")
  let g:UltiSnipsJumpBackwardTrigger="<s-tab>"
endif

au InsertEnter * exec "inoremap <silent> " . g:UltiSnipsExpandTrigger . " <C-R>=g:UltiSnips_Complete()<cr>"
au InsertEnter * exec "inoremap <silent> " . g:UltiSnipsJumpBackwardTrigger . " <C-R>=g:UltiSnips_Reverse()<cr>"

" ==================== Visual ==================== SECTION
autocmd FileType html setlocal shiftwidth=2 tabstop=2
autocmd FileType javascript setlocal shiftwidth=2 tabstop=2
autocmd FileType yaml setlocal ts=2 sts=2 sw=2 expandtab
autocmd FileType go setlocal ts=4 sts=4 sw=4 noexpandtab
autocmd FileType c setlocal ts=4 sts=4 sw=4 expandtab
autocmd BufRead,BufNewFile *.go :set filetype=go
autocmd BufRead,BufNewFile *.tag :set filetype=html
autocmd BufRead,BufNewFile *.vs :set filetype=c
autocmd BufRead,BufNewFile *.vue setlocal shiftwidth=2 tabstop=2

" ==================== Misc ==================== SECTION

" Fix highlighting breaking randomly
autocmd FileType vue syntax sync fromstart

" Make vue templates compatible with NERDCommenter
let g:ft = ''
function! NERDCommenter_before()
  if &ft == 'vue'
    let g:ft = 'vue'
    let stack = synstack(line('.'), col('.'))
    if len(stack) > 0
      let syn = synIDattr((stack)[0], 'name')
      if len(syn) > 0
        exe 'setf ' . substitute(tolower(syn), '^vue_', '', '')
      endif
    endif
  endif
endfunction

function! NERDCommenter_after()
  if g:ft == 'vue'
    setf vue
    let g:ft = ''
  endif
endfunction
