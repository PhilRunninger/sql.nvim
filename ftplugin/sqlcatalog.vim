" vim: foldmethod=marker
"
" Vim settings and a custom folding level function for the SQLCatalog buffer.

nnoremap <silent> <buffer> <Esc> :quit<CR>
nnoremap <silent> <buffer> q :quit<CR>
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

function s:Collapse()
    normal zc0
    if foldclosed('.') != -1
        call cursor(foldclosed('.'), 1)
    endif
endfunction

function s:ExpandOrOpenMenu()   " {{{1
    if foldclosed('.') != -1 && foldlevel('.') == 1
        normal! zo0
        return
    endif

    let type = search('^\S','bcnW')
    let object = search('^  \S','bcnW')
    if object < type
        return
    endif

    let type = getline(type)
    let actions = sql#settings#actions(type)
    let sqlBuffer = b:sqlBuffer
    let [platform, server, database] = [b:platform, b:server, b:database]
    let object = getline(object)[2:]->substitute('  {.*}$', '','')
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
    let [b:platform, b:server, b:database] = [platform, server, database]
    let [b:type, b:object] = [type, object]
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

