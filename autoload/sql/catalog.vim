"  vim: foldmethod=marker

let s:bufferName = '⟪SQLCatalog⟫'

function! sql#catalog#show() abort " {{{1
    try
        let bufferName = '⟪SQLCatalog⟫'
        let bufnr = bufnr(bufferName)
        if bufnr == -1
            let bufnr = bufnr(bufferName, 1)
            call nvim_buf_set_lines(bufnr,0,-1,0,sql#settings#servers())
        endif
        let winnr = bufwinnr(bufnr)
        if winnr == -1
            call nvim_open_win(bufnr,1,{'width':40, 'noautocmd':1, 'style':'minimal', 'vertical':1, 'win':-1})
            call nvim_set_option_value('filetype', 'sqlcatalog',    {'buf':bufnr})
        else
            execute winnr . 'wincmd w'
        endif
    catch
        " If the user config is invalid, bufnr will have been wiped out while
        " trying to add text to it. This catches that exception, but the
        " original error has already been handled.
    endtry
endfunction

function! sql#catalog#close(wipeout) abort " {{{1
    if a:wipeout
        let bufferName = '⟪SQLCatalog⟫'
        if bufexists(bufferName)
            execute 'bwipeout ' . bufferName
        endif
    else
        let winnr = winnr()
        execute bufwinnr(sql#bufnr()).'wincmd w'
        execute winnr.'wincmd c'
    endif
endfunction

function! sql#catalog#getLines() abort " {{{1
    return getbufline(s:bufferName, 1, '$')
endfunction
