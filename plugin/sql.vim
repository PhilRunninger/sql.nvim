"  vim: foldmethod=marker

call sql#settings#init(expand('<sfile>:p:h:h'))
call sql#state#read()

augroup SqlAuGroup
    autocmd!
    autocmd VimLeavePre * call sql#state#write()
    autocmd BufWritePost *.sql call sql#state#saveAs(expand('<abuf>'), expand('<afile>'))
augroup END

command! -nargs=1 -complete=customlist,<SID>SQLSubCommands SQL call <SID>Sql('<args>')

let s:subCommands = {
    \ 'new':          function('sql#new'),
    \ 'config':       function('sql#settings#edit'),
    \ 'fmt:markdown': function('sql#sqlout#convert', ['markdown']),
    \ 'fmt:ascii':    function('sql#sqlout#convert', ['ascii']),
    \ 'fmt:unicode':  function('sql#sqlout#convert', ['unicode']),
    \ }
function! s:SQLSubCommands(A,L,P) abort
    return sort(filter(keys(s:subCommands), {_,v -> v =~ "^" . a:A}))
endfunction

function! s:Sql(cmd) abort
    if has_key(s:subCommands, a:cmd)
        call s:subCommands[a:cmd]()
    else
        echohl ErrorMsg
        echo 'Unknown command: ' . a:cmd
        echohl None
    endif
endfunction
