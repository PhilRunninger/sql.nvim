"  vim: foldmethod=marker

function! sql#search#start(identifier = '') " {{{1
    let identifier = empty(a:identifier) ? input('Enter object name to search for: ') : a:identifier
    if empty(identifier)
        return
    endif

    let s:search = '\c^\s\{6}\S*\zs' . identifier
    call sql#search#next()
endfunction

function! sql#search#next(direction = 1) " {{{1
    if !exists('s:search')
        echo 'No search term specified. Use Ctrl+F3 first.'
        return
    endif

    if search(s:search, a:direction == 1 ? 'w' : 'b') == 0
        echo 'No match found among object names.'
        return
    endif

    normal! zv
endfunction
