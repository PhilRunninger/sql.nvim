"  vim: foldmethod=marker

function! sql#chooser#choose(prompt, choices)   " {{{1
    let s:choices = a:choices
    let response = input(a:prompt.' ', '', 'customlist,SQLCompletion')
    if index(a:choices, response) == -1
        throw '  Invalid selection. Aborting...'
    endif
    return response
endfunction

function! SQLCompletion(A, L, P) " {{{1
    return filter(copy(s:choices), {_,v -> v =~ a:A})
endfunction
