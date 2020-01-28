colorscheme minimalist

hi Normal guibg=NONE ctermbg=NONE ctermfg=NONE term=NONE cterm=NONE guifg=NONE
hi VertSplit term=NONE cterm=NONE guifg=NONE ctermbg=NONE guibg=NONE
hi LineNr ctermbg=NONE
hi EndOfBuffer ctermfg=black guifg=#444b71 guibg=NONE term=NONE cterm=NONE ctermbg=NONE

autocmd FileType html setlocal shiftwidth=2 tabstop=2
autocmd FileType javascript setlocal shiftwidth=2 tabstop=2
autocmd FileType yaml setlocal ts=2 sts=2 sw=2 expandtab
autocmd FileType go setlocal ts=4 sts=4 sw=4 noexpandtab
autocmd FileType c setlocal ts=4 sts=4 sw=4 expandtab
autocmd FileType typescript setlocal shiftwidth=2 tabstop=2 expandtab
autocmd FileType sass setlocal shiftwidth=2 tabstop=2
autocmd FileType sh setlocal shiftwidth=4 tabstop=4 expandtab
autocmd FileType terraform syn sync minlines=200
autocmd FileType terraform setlocal shiftwidth=2 tabstop=2 expandtab
autocmd BufRead,BufNewFile *.go :set filetype=go
autocmd BufRead,BufNewFile *.tag :set filetype=html
autocmd BufRead,BufNewFile *.vs :set filetype=c
autocmd BufRead,BufNewFile *.vue setlocal shiftwidth=2 tabstop=2
autocmd BufRead,BufNewFile *.jsx setlocal shiftwidth=2 tabstop=2 expandtab
