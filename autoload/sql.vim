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
    let connection = sql#state#getConnection(bufnr())
    let text = empty(connection) ? '%#ErrorMsg# Not connected ' : (join(connection[1:2],'.') . ' ')

    try
        let info = empty(connection) ? {} : sql#settings#serverInfo(connection[0],connection[1])
        call nvim_set_hl(0, 'SQLStatusline', info.highlight)
    catch
        call nvim_set_hl(0, 'SQLStatusline', {'link':'StatusLine'})
    endtry

    return '%#SQLStatusline# %l,%c %p%% ┃ %M ┃ %=%f%=┃ '.text
endfunction

