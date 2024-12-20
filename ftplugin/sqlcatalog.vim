" vim: foldmethod=marker
"
" Vim settings and a custom folding level function for the SQLCatalog buffer.

nnoremap <silent> <buffer> <Esc> :call <SID>CloseMe()<CR>
nnoremap <silent> <buffer> q :call <SID>CloseMe()<CR>
nnoremap <silent> <buffer> h :call <SID>Collapse()<CR>
nnoremap <silent> <buffer> l :call <SID>ExpandOrOpenMenu()<CR>
nnoremap <silent> <buffer> <Enter> :call <SID>SetConnection()<CR>

" TODO: In here <F5> will refresh the current database objects. Will need to
" delete lines from [z+1 to ]z. then repopulate them.

setlocal nomodifiable
setlocal bufhidden=hide buftype=nofile noswapfile
setlocal cursorline
setlocal nowrap nonumber norelativenumber nolist
setlocal foldopen-=search
setlocal conceallevel=3 concealcursor=nvic
setlocal fillchars=fold:\ ,eob:\  foldcolumn=0 foldmethod=expr foldexpr=SQLCatalogFoldLevel(v:lnum)
setlocal foldtext=getline(v:foldstart)

function! SQLCatalogFoldLevel(lnum)   " {{{1
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

function s:Collapse()   " {{{1
    if foldlevel('.') > 0
        normal zc0
    endif
    if foldclosed('.') != -1
        call cursor(foldclosed('.'), 1)
    endif
endfunction

function s:ExpandOrOpenMenu()   " {{{1
    if foldclosed('.') != -1
        normal! zo0
    endif

    let [server,platform] = matchlist(getline(search('^\S','bcnW')),    '^..\(.*\) (\(.*\))$')[1:2]
    let database          =  matchstr(getline(search('^  \S', 'bcnW')), '^  ..\zs.*\ze$')
    let type              =      trim(getline(search('^    \S','bcnW')))
    let object            =      trim(getline(search('^      \S','bcnW')))

    let currentLine = getline('.')
    if currentLine =~ '^○'    " Unexplored server
        let masterDB = sql#settings#app()[platform].actions.Catalog.masterDB
        call sql#query#run(function('s:GetDBInfoCallback', [line('.'), '  ○ ']), platform, server, masterDB, 'Catalog', 'GetDatabases')
    elseif currentLine =~ '^  ○'    " Unexplored database
        call sql#query#run(function('s:GetDBInfoCallback', [line('.'), '    ']), platform, server, database, 'Catalog', 'GetDatabaseObjects')
    elseif currentLine =~ '^      \(  \)\?'   " DB Object or Type
        call sql#actions#openWindow(platform, server, database, type, object)
    endif
endfunction

function! s:GetDBInfoCallback(line, prefix, job_id, data, event) " {{{1
    stopinsert
    call sql#showCatalog()
    setlocal modifiable
    call nvim_buf_set_lines(0,a:line-1,a:line,0,[substitute(getline(a:line), '○', '●', '')])
    call nvim_buf_set_lines(0,a:line,a:line,0,map(filter(a:data,{_,v -> !empty(v)}), {_,v -> a:prefix.substitute(v, nr2char(13).'$','','')}))
    setlocal nomodifiable
    normal! zmzv0
endfunction

function! s:CloseMe()   "{{{1
    let winnr = winnr()
    execute bufwinnr(sql#bufnr()).'wincmd w'
    execute winnr.'wincmd c'
endfunction

function! s:SetConnection() " {{{1
    if getline('.') !~ '^  '
        echo 'Your cursor must be on a database name to choose a connection.'
        return
    endif

    let [server,platform] = matchlist(getline(search('^\S','bcnW')),    '^..\(.*\) (\(.*\))$')[1:2]
    let database          =  matchstr(getline(search('^  \S', 'bcnW')), '^  ..\zs.*\ze$')
    call sql#connection#set(platform, server, database)
endfunction
