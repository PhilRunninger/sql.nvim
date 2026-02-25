"  vim: foldmethod=marker

function! sql#search#start(identifier = '') " {{{1
    if &filetype == 'sql'
        " Set up the return-to SQL buffer.
        call sql#bufnr(bufnr())
    endif
    call sql#showCatalog()

    let identifier = empty(a:identifier) ? input('Enter object name to search for: ') : printf('\<%s\>', a:identifier)
    if empty(identifier)
        return
    endif

    let s:search = '\c^\s\{6}\S*\zs' . identifier
    call sql#search#next()
endfunction

function! sql#search#next(direction = 1) " {{{1
    if !exists('s:search')
        echohl WarningMsg
        echo 'No search term specified. Use Ctrl+F3 first.'
        echohl None
        return
    endif

    if search(s:search, a:direction == 1 ? 'w' : 'b') == 0
        echohl ErrorMsg
        echo 'No match found among object names.'
        echohl None
        return
    endif

    normal! zv
endfunction
