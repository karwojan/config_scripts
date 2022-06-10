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

let b:ale_linters = ['eclipselsp']

setlocal omnifunc=ale#completion#OmniFunc
