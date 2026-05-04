"  vim: foldmethod=marker

" These are essentially the global variables for this plugin. " {{{1
let sql#explored = '▶'
let sql#unexplored = '▷'

let s:bufnr = 0
function! sql#bufnr(bufnr = 0)
    let s:bufnr = a:bufnr == 0 ? s:bufnr : a:bufnr
    return s:bufnr
endfunction

function! sql#new() "{{{1
    let freeWindows = filter(range(1,winnr('$')), {_,w -> !getwinvar(w,'&winfixbuf')})
    if empty(freeWindows)
        1wincmd w
        aboveleft new
    elseif &winfixbuf == 1
        execute freeWindows[0] . 'wincmd w'
    endif

    if bufname('%') != '' || &modified
        enew
    endif
    set filetype=sql
    return sql#bufnr(bufnr())
endfunction

function! sql#showSQL() " {{{1
    let bufnr = sql#bufnr()
    if !bufexists(bufnr)
        let bufnr = sql#new()
    endif

    let winnr = bufwinnr(bufnr)
    let freeWindows = filter(range(1,winnr('$')), {_,w -> !getwinvar(w,'&winfixbuf')})
    if empty(freeWindows)
        1wincmd w
        execute 'aboveleft sbuffer ' . bufnr
    elseif winnr == -1
        execute freeWindows[0] . 'wincmd w'
        execute 'buffer ' . bufnr
    else
        execute winnr . 'wincmd w'
    endif
endfunction

function! sql#statusline() abort " {{{1
    if empty(sql#connection#get())
        return '%l/%L %c%=%f%=%#ErrorMsg# Not connected '
    else
        return '%l/%L %c%=%f%=%{join(sql#connection#get()[1:2],".")} '
    endif
endfunction

