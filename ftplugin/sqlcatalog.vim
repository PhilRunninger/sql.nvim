" vim: foldmethod=marker
"
" Vim settings and a custom folding level function for the SQLCatalog buffer.

nnoremap <silent> <buffer> <Esc> :call <SID>CloseMe()<CR>
nnoremap <silent> <buffer> q :call <SID>CloseMe()<CR>
nnoremap <silent> <buffer> h :call <SID>Collapse()<CR>
nnoremap <silent> <buffer> l :call <SID>ExpandOrOpenMenu()<CR>
nnoremap <silent> <buffer> <Enter> :call <SID>SetConnection()<CR>
nnoremap <silent> <buffer> <F5> :call <SID>Refresh()<CR>
nnoremap <silent> <buffer> <F8> :call sql#showSQL()<CR>
nnoremap <silent> <buffer> J ]z
nnoremap <silent> <buffer> K [z

setlocal nomodifiable
setlocal bufhidden=hide buftype=nofile noswapfile
setlocal cursorline
setlocal nowrap nonumber norelativenumber nolist
setlocal foldopen-=search
setlocal conceallevel=3 concealcursor=nvic
setlocal fillchars=fold:\ ,eob:\  foldcolumn=0 foldmethod=expr foldexpr=SQLCatalogFoldLevel(v:lnum)
setlocal foldtext=getline(v:foldstart)

function! SQLCatalogFoldLevel(lnum) " {{{1
    let l:current_indent = 1 + len(matchstr(getline(a:lnum),'^ *')) / 2
    let l:next_indent = 1 + len(matchstr(getline(a:lnum + 1),'^ *')) / 2

    if a:lnum == line('$')
        return '<1'
    elseif l:current_indent < l:next_indent
        return '>' . l:current_indent
    elseif l:current_indent > l:next_indent
        return '<' . (l:current_indent - 1)
    else
        return l:current_indent - 1
    endif
endfunction

function! s:Collapse() " {{{1
    if foldlevel('.') > 0
        normal zc0
    endif
    if foldclosed('.') != -1
        call cursor(foldclosed('.'), 1)
    endif
endfunction

function! s:ExpandOrOpenMenu() " {{{1
    if foldclosed('.') != -1
        normal! zo0
    endif

    let current = s:ObjectUnderCursor()
    if current.cursor.text =~ '^○'    " Unexplored server
        let masterDB = sql#settings#app()[current.platform.text].actions.Catalog.masterDB
        call sql#query#run(function('s:GetDBInfoCallback', [current.cursor.line, '  ○ ']), current.platform.text, current.server.text, masterDB, 'Catalog', 'GetDatabases')
    elseif current.cursor.text =~ '^  ○'    " Unexplored database
        call sql#query#run(function('s:GetDBInfoCallback', [current.cursor.line, '    ']), current.platform.text, current.server.text, current.database.text, 'Catalog', 'GetDatabaseObjects')
    elseif current.cursor.text =~ '^      \(  \)\?'   " DB Object or Type
        call sql#actions#openWindow(current.platform.text, current.server.text, current.database.text, current.type.text, current.object.text)
    endif
endfunction

function! s:Refresh() " {{{1
    setlocal modifiable
    let current = s:ObjectUnderCursor()
    if current.cursor.text =~ '^[○●]'    " Refresh databases on server
        call cursor(current.server.line, 1)
        normal! ]z
        let lastLine = line('.')
        call nvim_buf_set_lines(0,current.server.line-1,lastLine,0,[printf('○ %s (%s)', current.server.text, current.platform.text)])
        call cursor(current.server.line, 1)
    else    " Refresh database objects
        call cursor(current.database.line, 1)
        normal! ]z
        let lastLine = line('.')
        call nvim_buf_set_lines(0,current.database.line-1,lastLine,0,[printf('  ○ %s', current.database.text)])
        call cursor(current.database.line, 1)
    endif
    setlocal nomodifiable
    call s:ExpandOrOpenMenu()   " Allow the Expand functionality to repopulate the removed items.
endfunction

function! s:GetDBInfoCallback(line, prefix, job_id, data, event) " {{{1
    stopinsert
    call sql#showCatalog()
    if empty(filter(copy(a:data),{_,v -> !empty(v)}))
        return
    endif

    setlocal modifiable
    call nvim_buf_set_lines(0,a:line-1,a:line,0,[substitute(getline(a:line), '○', '●', '')])
    call nvim_buf_set_lines(0,a:line,a:line,0,map(filter(a:data,{_,v -> !empty(v)}), {_,v -> a:prefix.substitute(v, nr2char(13).'$','','')}))
    setlocal nomodifiable
    call cursor(a:line,1)
    normal! zmzv0
endfunction

function! s:CloseMe() " {{{1
    let winnr = winnr()
    execute bufwinnr(sql#bufnr()).'wincmd w'
    execute winnr.'wincmd c'
endfunction

function! s:SetConnection() " {{{1
    if getline('.') !~ '^  '
        echo 'Your cursor must be within a database to choose a connection.'
        return
    endif

    let current = s:ObjectUnderCursor()
    call sql#connection#set(current.platform.text, current.server.text, current.database.text)
endfunction

function! s:ObjectUnderCursor() " {{{1
    let server   = search('^\S','bcnW')
    let database = search('^  \S', 'bcnW')
    let type     = search('^    \S','bcnW')
    let object   = search('^      \S','bcnW')

    return #{
        \ cursor:   #{line: line('.'), text: getline('.')},
        \ server:   #{line: server,    text: matchlist(getline(server), '^..\(.*\) (\(.*\))$')[1]},
        \ platform: #{line: server,    text: matchlist(getline(server), '^..\(.*\) (\(.*\))$')[2]},
        \ database: #{line: database,  text: matchstr(getline(database), '^  ..\zs.*\ze$')},
        \ type:     #{line: type,      text: trim(getline(type))},
        \ object:   #{line: object,    text: trim(getline(object))}
        \ }
endfunction

