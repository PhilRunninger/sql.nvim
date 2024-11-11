nnoremap <silent> <buffer> h :call nvim_win_hide(0)<CR>
nnoremap <silent> <buffer> l :call <SID>RunAction()<CR>

function! s:RunAction()
    let action = getline('.')
    call sql#query#run(function('s:RunActionCallback'), b:platform, b:server, b:database, b:type, action, {'object':b:object})
endfunction

function! s:RunActionCallback(job_id, data, event)
    stopinsert
    let data = map(a:data, {_,v -> substitute(v, nr2char(13).'$', '', '')})
    echomsg 'going to window '. bufwinnr(sql#bufNr())
    execute bufwinnr(sql#bufNr()).'wincmd w'
    let @"=join(data, nr2char(10))
    echo 'Result is ready to paste.'
endfunction

