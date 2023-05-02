"header files for C/C++
function! PrepareHeader()
    let filename = toupper(strpart(expand('%:t'), 0, match(expand('%:t'), "\\.")))
    call setline(1, "#ifndef " . filename . "_H")
    call setline(2, "#define " . filename . "_H")
    call setline(3, "#endif //" . filename . "_H")
    call append(2, "")
    call append(2, "")
    call append(2, "")
endfunction
autocmd BufNewFile *.h :call PrepareHeader()

" ALE config
let b:ale_linters = ["clangd"]
let g:ale_virtualtext_cursor = "0"
let g:ale_completion_enabled = 1
set omnifunc=ale#completion#OmniFunc

nnoremap <buffer> <LocalLeader>d :ALEGoToDefinition<CR>
nnoremap <buffer> <LocalLeader>D :ALEGoToTypeDefinition<CR>
nnoremap <buffer> <LocalLeader>n :ALEFindReferences<CR>
nnoremap <buffer> <LocalLeader>r :ALERename<CR>
nnoremap <buffer> <LocalLeader>a :ALECodeAction<CR>
nnoremap <buffer> K :ALEHover<CR>
