" vim: foldmethod=marker
"
" Vim settings and a custom folding level function for the SQLCatalog buffer.

nnoremap <silent> <buffer> <Esc> :call <SID>CloseMe()<CR>
nnoremap <silent> <buffer> q :call <SID>CloseMe()<CR>
nnoremap <silent> <buffer> h :call <SID>Collapse()<CR>
nnoremap <silent> <buffer> l :call <SID>ExpandOrOpenMenu()<CR>
nnoremap <silent> <buffer> <leader>l zo0

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
    normal zc0
    if foldclosed('.') != -1
        call cursor(foldclosed('.'), 1)
    endif
endfunction

function s:ExpandOrOpenMenu()   " {{{1
    if foldclosed('.') != -1 && foldlevel('.') <= 3
        normal! zo0
        return
    endif

    let server   = search('^\S', 'bcnW')
    let database = search('^  \S', 'bcnW')
    let type     = search('^    \S','bcnW')
    let object   = search('^      \S','bcnW')

    let currentLine = getline('.')
    if currentLine =~# '^○'
        call s:GetDatabases(matchlist(currentLine, '^..\(.*\) (\(.*\))$')[1:2])
    elseif currentLine =~# '^  ○'
        call s:GetDatabaseObjects(
        \   matchlist(getline(server), '^..\(.*\) (\(.*\))$')[1:2],
        \   matchlist(currentLine, '^  ..\(.*\)$')[1])
    elseif currentLine =~# '^    \(  \)\?'
        call s:ShowActionsWindow(
        \   matchlist(getline(server), '^..\(.*\) (\(.*\))$')[1:2],
        \   matchlist(getline(database), '^  ..\(.*\)$')[1],
        \   trim(getline(type)),
        \   trim(getline(object)))
    endif
endfunction

function! s:GetDatabases(server) " {{{1
    let [server, platform] = a:server
    call sql#query#run(function('s:GetDatabasesCallback', [line('.')]), platform, server, 'master', 'Catalog', 'GetDatabases')
endfunction

function! s:GetDatabasesCallback(line, job_id, data, event)
    stopinsert
    call sql#showCatalog()
    setlocal modifiable
    echomsg string(a:data)
    echomsg string(map(copy(a:data),{_,v -> empty(v)}))
    echomsg string(filter(copy(a:data),{_,v -> !empty(v)}))
    echomsg string(map(filter(copy(a:data),{_,v -> !empty(v)}), {_,v -> '  ○ '.substitute(v, nr2char(13).'$','','')}))
    call nvim_buf_set_lines(0,a:line,a:line,0,map(filter(a:data,{_,v -> !empty(v)}), {_,v -> '  ○ '.substitute(v, nr2char(13).'$','','')}))
    setlocal nomodifiable
endfunction

function! s:GetDatabaseObjects(server, database) " {{{1
    let [server, platform] = a:server
endfunction

function! s:ShowActionsWindow(server, database, type, object) " {{{1
    let [server, platform] = a:server
    let actions = sql#settings#actions(platform, a:type)
    let sqlBuffer = b:sqlBuffer
    let object = object->substitute('  {.*}$', '','')
    let config = {
        \ 'relative': 'cursor',
        \ 'anchor': 'NW',
        \ 'row': 0,
        \ 'col': 2+len(object),
        \ 'height': len(actions),
        \ 'width': max(map(copy(actions), {_,v -> len(v)})),
        \ 'noautocmd': 1,
        \ 'style': 'minimal',
        \ 'border': 'double',
        \ 'title': 'Actions'
    \ }
    let s:actionsWindow = nvim_open_win(nvim_create_buf(0,1),1,config)
    augroup SqlAuGroup
        autocmd!
        autocmd BufLeave <buffer> call s:CloseActionsWindow()
    augroup END

    setlocal modifiable filetype=sqlactions
    let b:sqlBuffer = sqlBuffer
    let [b:platform, b:server, b:database] = [platform, server, a:database]
    let [b:type, b:object] = [a:type, object]
    silent %delete _
    call setline(1, actions)
    setlocal nomodifiable
endfunction

function! s:CloseActionsWindow()   "{{{1
    if exists('s:actionsWindow')
        call nvim_win_hide(s:actionsWindow)
    endif
    unlet! s:actionsWindow
endfunction

function! s:CloseMe()   "{{{1
    let winnr = winnr()
    wincmd p
    execute winnr.'wincmd c'
endfunction
