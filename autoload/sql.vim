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

function! sql#showCatalog() abort " {{{1
    let bufferName = '⟪SQLCatalog⟫'
    let bufnr = bufnr(bufferName)
    if bufnr == -1
        let bufnr = bufnr(bufferName, 1)
        call nvim_buf_set_lines(bufnr,0,-1,0,sql#settings#servers())
    endif
    let winnr = bufwinnr(bufnr)
    if winnr == -1
        call nvim_open_win(bufnr,1,{'width':40, 'noautocmd':1, 'style':'minimal', 'split':'right', 'win':-1})
        call nvim_set_option_value('filetype', 'sqlcatalog',    {'buf':bufnr})
    else
        execute winnr . 'wincmd w'
    endif
endfunction
