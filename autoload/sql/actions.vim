"  vim: foldmethod=marker

function! sql#actions#openWindow(platform, server, database, type, object)   " {{{1
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
        \ 'border': 'rounded',
        \ 'title': 'Actions'
    \ }
    let s:actionsWindow = nvim_open_win(nvim_create_buf(0,1),1,config)
    augroup SqlAuGroup
        autocmd!
        autocmd BufLeave <buffer> call sql#actions#closeWindow()
    augroup END

    setlocal modifiable filetype=sqlactions
    call nvim_buf_set_lines(0, 0, line('$'), 1, actions)
    setlocal nomodifiable
endfunction

function! sql#actions#run(action, newBuffer) " {{{1
    call sql#query#run(function('s:RunActionCallback', [a:newBuffer, a:action]), sql#settings#delimiter(s:platform), s:platform, s:server, s:database, s:type, a:action, {'object':s:object})
endfunction

function! s:RunActionCallback(newBuffer, action, job_id, data, event)
    stopinsert

    let data = map(a:data, {_,v -> substitute(v, nr2char(13).'$', '', '')})
    for i in range(len(data)-1,0,-1)
        if data[i] == 'J3o.i1n4N1e5x9t2L6i5n3e5T8o9P7r9e3v2i3o8u4s6'
            let data[i-1] .= data[i+1]
            call remove(data, i, i+1)
        endif
    endfor

    call sql#actions#closeWindow()
    call sql#showSQL()
    if a:newBuffer
        execute 'edit ' . a:action . ' ' . s:database . '.' . s:object . '.sql'
        setlocal bufhidden=hide buftype=nofile noswapfile
        let saveBufnr = sql#bufnr()
        let bufnr = sql#bufnr(bufnr())
        call sql#state#setConnection(bufnr, s:platform, s:server, s:database)
        call nvim_buf_set_lines(bufnr, 0, line('$'), 1, data)
        call sql#bufnr(saveBufnr)
    else
        call setreg(&clipboard =~? 'unnamedplus' ? '+' : &clipboard =~? 'unnamed' ? '*' : '', data, 'l')
        echo 'Result is ready to paste.'
    endif
endfunction

function! sql#actions#closeWindow() " {{{1
    if exists('s:actionsWindow')
        call nvim_win_hide(s:actionsWindow)
    endif
    unlet! s:actionsWindow
endfunction

