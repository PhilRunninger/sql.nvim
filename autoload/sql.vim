let s:bufnr = 0
function! sql#bufnr(bufnr = 0)
    let s:bufnr = a:bufnr == 0 ? s:bufnr : a:bufnr
    return s:bufnr
endfunction

let s:platform = ''
function! sql#platform(platform = '')
    let s:platform = empty(a:platform) ? s:platform : a:platform
    return s:platform
endfunction

let s:server = ''
function! sql#server(server = '')
    let s:server = empty(a:server) ? s:server : a:server
    return s:server
endfunction

let s:database = ''
function! sql#database(database = '')
    let s:database = empty(a:database) ? s:database : a:database
    return s:database
endfunction

function! sql#new()
    if bufname('%')!='' || &modified
        tabnew
    endif
    set filetype=sql
    call sql#bufnr(bufnr())
    call sql#showCatalog()
endfunction

function! sql#showCatalog() " {{{1
    let catalogBufNr = bufnr('^SQLCatalog$')
    if catalogBufNr == -1
        let catalogBufNr = bufnr('^SQLCatalog$', 1)
        let serverlist = sort(flatten(
        \   map(keys(sql#settings#user()),{_,p ->
        \       map(keys(sql#settings#user()[p].servers), {_,s -> '○ '.s.' ('.p.')'})})))
        call nvim_buf_set_lines(catalogBufNr,0,-1,0,serverlist)
        keeppatterns silent g/^$/d
    endif
    let winnr = bufwinnr(catalogBufNr)
    if winnr == -1
        call nvim_open_win(catalogBufNr,1,{'width':40, 'noautocmd':1, 'style':'minimal', 'split':'right', 'win':-1})
        call nvim_set_option_value('filetype', 'sqlcatalog',    {'buf':catalogBufNr})
    else
        execute winnr . 'wincmd w'
    endif
endfunction
