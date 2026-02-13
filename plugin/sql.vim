"  vim: foldmethod=marker

call sql#settings#init(expand('<sfile>:p:h:h'))

command! -nargs=1 -complete=customlist,<SID>SQLSubCommands SQL call <SID>Sql('<args>')

let s:subCommands = {
    \ 'new':    function('sql#new'),
    \ 'config': function('sql#settings#edit'),
    \ 'md':     function('sql#sqlout#toMarkdown'),
    \ }
function! s:SQLSubCommands(A,L,P) abort
    return filter(keys(s:subCommands), {_,v -> v =~ "^" . a:A})
endfunction

function! s:Sql(cmd) abort
    if has_key(s:subCommands, a:cmd)
        call s:subCommands[a:cmd]()
    else
        echohl ErrorMsg
        echo 'Unknown command: ' . a:cmd
    endif
endfunction
