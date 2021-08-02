" Vim python filetype plugin, which helps a lot with python code development
" Last Change: 2021-04-28
" Maintainer: Jan Karwowski <jan.karwowski@tlen.pl>
" License: This file is placed in the public domain


" Executing python code in terminal window
function CloseSnippetWindow()
    if bufwinnr(b:snippet_buffer) != -1
        execute bufwinnr(b:snippet_buffer) . 'hide'
    endif
endfunction
function SnippetWindowExists()
    return exists('b:snippet_buffer') && index(term_list(), b:snippet_buffer) != -1 && term_getstatus(b:snippet_buffer) == 'running'
endfunction
function ExecuteInPython3(text)
    if !SnippetWindowExists()
        let b:snippet_buffer = term_start('python3', {'hidden':1})
        let snippet_buffer = b:snippet_buffer
        call term_sendkeys(snippet_buffer, "import sys\n")
        call term_sendkeys(snippet_buffer, "sys.path.append('" . expand('%:h') . "')\n")
        autocmd QuitPre <buffer> call term_setkill(b:snippet_buffer, "kill")
        noremap <buffer> <Esc> :call CloseSnippetWindow()<CR>
    else
        let snippet_buffer = b:snippet_buffer
    endif
    let current_window_id = bufwinid(bufnr('%'))
    if bufwinnr(snippet_buffer) == -1
        execute 'sbuffer ' . snippet_buffer
        call win_gotoid(current_window_id)
    endif
    call term_sendkeys(snippet_buffer, a:text . "\n")
endfunction
noremap <buffer> <F1> :!python3 %<CR>
noremap <buffer> <F2> :!python3 -i %<CR>
nnoremap <buffer> <Space> :call ExecuteInPython3(getline(line('.')))<CR>
vnoremap <buffer> <Space> "zy:call ExecuteInPython3(@z)<CR>




" Python debugger
highlight PDBBreakpointLineHighlight ctermbg=White ctermfg=Red
highlight PDBCurrentLineHighlight ctermbg=Grey
sign define pdb_breakpoint_line text=B linehl=PDBBreakpointLineHighlight
sign define pdb_current_line text=>> linehl=PDBCurrentLineHighlight texthl=PDBCurrentLineHighlight

let maplocalleader = ','
map <buffer> <LocalLeader>g :call PDBGoToCurrentLine()<CR>
map <buffer> <LocalLeader>s :call PDBStart()<CR>
map <buffer> <LocalLeader>S :call PDBStop()<CR>
map <buffer> <LocalLeader>n :call PDBNext()<CR>
map <buffer> <LocalLeader>c :call PDBContinue()<CR>
map <buffer> <LocalLeader>b :call PDBBreakpoint()<CR>
nmap <buffer> <LocalLeader>p "zyiw:call PDBEvaluate(@z)<CR>
vmap <buffer> <LocalLeader>p "zy:call PDBEvaluate(@z)<CR>

if !exists('*PDBGoToCurrentLine')
    function PDBGoToCurrentLine()
        for line in range(term_getsize(g:pdb_buffer)[0], 1, -1)
            let match = matchlist(term_getline(g:pdb_buffer, line), '^> \([^(]\+\)(\(\d\+\))')
            if len(match) > 0
                execute 'edit ' . match[1]
                call cursor(match[2], 1)
                call sign_unplace("", {'id': 1})
                call sign_place(1, "", 'pdb_current_line', bufnr(""), {'lnum': line('.')})
                break
            endif
        endfor
    endfunction
endif
if !exists('*PDBStart')
    function PDBStart()
        if !exists('g:pdb_buffer')
            let current_window_id = bufwinid(bufnr("%"))
            let g:pdb_buffer = term_start('python3 -m pdb ' . expand('%:p'), {'term_rows': 10})
            call win_gotoid(current_window_id)
            autocmd QuitPre <buffer> call term_setkill(g:pdb_buffer, "kill")
        endif
    endfunction
endif
if !exists('*PDBStop')
    function PDBStop()
        if exists('g:pdb_buffer')
            call term_setkill(g:pdb_buffer, "kill")
            execute bufwinnr(g:pdb_buffer) . 'hide'
            call sign_unplace("")
            unlet g:pdb_buffer
        endif
    endfunction
endif
if !exists('*PDBNext')
    function PDBNext()
        call term_sendkeys(g:pdb_buffer, "next\n")
    endfunction
endif
if !exists('*PDBContinue')
    function PDBContinue()
        call term_sendkeys(g:pdb_buffer, "continue\n")
    endfunction
endif
if !exists('*PDBBreakpoint')
    function PDBBreakpoint()
        call term_sendkeys(g:pdb_buffer, "break " . expand('%:p') . ":" . line('.') . "\n")
        call sign_place(0, "", 'pdb_breakpoint_line', bufnr(""), {'lnum': line('.')})
    endfunction
endif
if !exists('*PDBEvaluate')
    function PDBEvaluate(expression)
        call term_sendkeys(g:pdb_buffer, "p " . a:expression . "\n")
    endfunction
endif
