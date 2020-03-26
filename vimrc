source $VIMRUNTIME/defaults.vim

"indents
set smartindent tabstop=4 shiftwidth=4 expandtab

"searching
set ignorecase smartcase hlsearch

"folding
set foldmethod=syntax
autocmd BufReadPost * normal zR

"encryption
set cm=blowfish2

"path for C/C++ header files (from gcc/g++ compiler)
set path=.,,include,/usr/include,/usr/local/include,/usr/lib/gcc/x86_64-redhat-linux/8/include,/usr/include/c++/8,/usr/include/c++/8/x86_64-redhat-linux,/include/c++/8/backward

"NERDTree started when ther is no file selected while entering Vim
function! LaunchNERDTree()
    if @% == ""
        NERDTree
    endif
endfunction
autocmd VimEnter * call LaunchNERDTree()

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

"Helpful function to format Java sourcode via intellij
function! FormatCode()
    call system("/snap/intellij-idea-community/current/bin/format.sh " . @%)
    edit!
endfunction
command! Format :call FormatCode()

"Helpful function to generate and paste UUID
function! GenerateUUID()
    let uuid = system("uuidgen")
    let uuid = strcharpart(uuid, 0, strlen(uuid) - 2)
    call setreg('"', uuid)
endfunction
noremap <F9> :call GenerateUUID()<CR>p

"Helpful function to recursive find file containing passed text
function! FindFile(suffix)
    let g:currentFilename = @%
    let g:suffix = a:suffix
    enew!
    function! FindAndPrintFiles()
        let filename = getline(1)
        if strchars(filename) > 2
            let files = systemlist('find ./ -iname "*' . filename . '*."' . g:suffix)
            if(line("$") > 1)
                2;$g/./d
                call cursor(line("."), col("$"))
            endif
            call append(line("$"), files)
        endif
    endfunction
    autocmd! TextChangedI <buffer> call FindAndPrintFiles()
    noremap <buffer> <CR> :execute "edit! " . getline(line("."))<CR>
    noremap <buffer> <ESC> :execute "edit! " . g:currentFilename<CR>
endfunction
command! -nargs=1 FindFile :call FindFile("<args>")

"tags
function! GenerateTags()
    echo "Generating..."

    "read old files hash from metadata
    let old_files_hash = {}
    if filereadable(".tags_metadata")
        let lines = readfile(".tags_metadata")
        for i in lines
            let filename = split(i, " ")[0]
            let hash = split(i, " ")[1]
            let old_files_hash[filename] = hash
        endfor
    endif

    "create current files hash
    let current_files_hash = {}
    let files = systemlist("find ./ -name '*.java'")
    for filename in files
        let hash = split(system("sha256sum " . filename), " ")[0]
        let current_files_hash[filename] = hash
    endfor

    "create list of modified files
    let modified_filenames = []
    for i in keys(current_files_hash)
        if has_key(old_files_hash, i)
            if old_files_hash[i] != current_files_hash[i]
                call add(modified_filenames, i)
            endif
        else
            call add(modified_filenames, i)
        endif
    endfor

    "generate tags
    for i in modified_filenames
        call system("ctags --append " . i)
    endfor

    "save new metadata
    let lines = []
    for [filename, hash] in items(current_files_hash)
        call add(lines, filename . " " . hash)
    endfor
    call writefile(lines, ".tags_metadata")

    echo "Done"
endfunction
autocmd BufWritePost *.java call system("ctags --append " . @%)

"JavaComplete
autocmd Filetype java setlocal omnifunc=javacomplete#Complete
autocmd Filetype java :let g:JavaComplete_ClasspathGenerationOrder = ['Maven']
