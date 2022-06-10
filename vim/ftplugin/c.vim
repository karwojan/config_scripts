"path for C/C++ header files
set path=.,,include,/usr/include,/usr/local/include
if has_key(environ(), 'IDF_PATH')
    set path+=~/esp/esp-idf/components/*/include
endif

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
