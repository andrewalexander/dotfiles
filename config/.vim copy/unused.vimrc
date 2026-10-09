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
