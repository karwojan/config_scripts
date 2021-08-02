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

"path for C/C++ header files
set path=.,,include,/usr/include,/usr/local/include
if has_key(environ(), 'IDF_PATH')
    set path+=~/esp/esp-idf/components/*/include
endif

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

"Formatting functions
function! FormatUsingExternalTool(cmd)
    let unformattedJson = join(getline(1, line("$")), "\n")
    let formattedJson = systemlist(a:cmd, unformattedJson)
    g/.*/d
    call setline(1, formattedJson)
endfunction
function! FormatSource()
    if &filetype == "java"
        call FormatUsingExternalTool("java --add-exports jdk.compiler/com.sun.tools.javac.api=ALL-UNNAMED --add-exports jdk.compiler/com.sun.tools.javac.file=ALL-UNNAMED --add-exports jdk.compiler/com.sun.tools.javac.parser=ALL-UNNAMED --add-exports jdk.compiler/com.sun.tools.javac.tree=ALL-UNNAMED --add-exports jdk.compiler/com.sun.tools.javac.util=ALL-UNNAMED -jar ~/.vim/google-java-format-all-deps.jar -")
    elseif &filetype == "json"
        call FormatUsingExternalTool("python3 -m json.tool")
    elseif &filetype == "xml"
        call FormatUsingExternalTool("xmllint --format -")
    elseif &filetype == "python"
        if executable("yapf")
            call FormatUsingExternalTool("yapf")
        else
            call FormatUsingExternalTool("yapf3")
        endif
    endif
endfunction
command! Format :call FormatSource()

"Helpful function to generate and paste UUID
function! GenerateUUID()
    let uuid = system("uuidgen")
    let uuid = strcharpart(uuid, 0, strlen(uuid) - 1)
    call setreg('"', uuid)
endfunction
command! GenerateUUID :call GenerateUUID()

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
    startinsert
    setlocal cursorline
endfunction
command! -nargs=1 FindFile :call FindFile("<args>")
autocmd! FileType java noremap <F1> :FindFile java<CR>

"tags for java
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

"ALE
let g:ale_linters = {'java': ['eclipselsp']}
autocmd Filetype java setlocal omnifunc=ale#completion#OmniFunc

"JDB
function! EnableJDBMapping()
    let g:jdb_breakpoints = []
    function! ToggleBreakpoint()
        let position = @% . ":" . line(".")
        if count(g:jdb_breakpoints, position) == 1
            call remove(g:jdb_breakpoints, index(g:jdb_breakpoints, position))
            JDBClearBreakpointOnLine
        else
            call add(g:jdb_breakpoints, position)
            JDBBreakpointOnLine
        endif
    endfunction
    noremap <F1> :call ToggleBreakpoint()<CR>
    noremap <F2> :JDBStepOver
    noremap <F3> viwy:JDBCommand print "<CR>
endfunction
command! EnableJDBMapping :call EnableJDBMapping()

"jedi-vim
let g:jedi#popup_on_dot = 0
let g:jedi#show_call_signatures = "0"

"bash
autocmd FileType sh noremap <F1> :!./%<CR>

"latex
function! CountWords() range
    echo len(split(join(getline(a:firstline, a:lastline))))
endfunction
function! CountCharacters() range
    echo len(join(getline(a:firstline, a:lastline)))
endfunction
function! CompileLatex()
    %s/\(\_s\w\)\_s\(\w\)/\1\~\2/g
    w
    !pdflatex %
    u
    w
endfunction
autocmd FileType tex noremap <F1> :call CompileLatex()<CR>
autocmd FileType tex setlocal spell spelllang=pl textwidth=100 spellcapcheck=
