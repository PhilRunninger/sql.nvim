"  vim: foldmethod=marker

function! sql#actions#openWindow(platform, server, database, type, object)
    let [s:platform, s:server, s:database] = [a:platform, a:server, a:database]
    let [s:type, s:object] = [a:type, a:object->substitute('  {.*}$', '','')]

    let actions = sql#settings#actions(a:platform, a:type)
    if empty(actions)
        return
    endif

    let config = {
        \ 'relative': 'cursor',
        \ 'anchor': 'NW',
        \ 'row': 0,
        \ 'col': 2+len(s:object),
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
        autocmd BufLeave <buffer> call sql#actions#closeWindow()
    augroup END

    setlocal modifiable filetype=sqlactions
    silent %delete _
    call setline(1, actions)
    setlocal nomodifiable
endfunction

function! sql#actions#run(action) " {{{1
    call sql#query#run(function('s:RunActionCallback'), s:platform, s:server, s:database, s:type, a:action, {'object':s:object})
endfunction

function! s:RunActionCallback(job_id, data, event)
    stopinsert
    let data = map(a:data, {_,v -> substitute(v, nr2char(13).'$', '', '')})
    execute bufwinnr(sql#bufnr()).'wincmd w'
    let @"=join(data, nr2char(10))
    echo 'Result is ready to paste.'
endfunction

function! sql#actions#closeWindow()   "{{{1
    if exists('s:actionsWindow')
        call nvim_win_hide(s:actionsWindow)
    endif
    unlet! s:actionsWindow
endfunction

