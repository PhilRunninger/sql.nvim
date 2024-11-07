nnoremap <silent> <buffer> h :call nvim_win_hide(0)<CR>
nnoremap <silent> <buffer> l :call <SID>RunAction()<CR>

function! s:RunAction()
    if !sql#connection#isSet() && !sql#connection#set()
        return
    endif

    let action = getline('.')
    let winnr = bufwinnr(b:sqlBuffer)
    call sql#query#run(function('s:RunActionCallback', [winnr]), b:platform, b:server, b:database, b:type, action, {'object':b:object})
endfunction

function! s:RunActionCallback(winnr, job_id, data, event)
    stopinsert
    let data = map(a:data, {_,v -> substitute(v, nr2char(13).'$', '', '')})
    execute a:winnr.'wincmd w'
    let @"=join(data, nr2char(10))
    echo 'Result is in the unnamed register.'
endfunction

