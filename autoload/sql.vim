const s:catalogBuffer = 'SQLCatalog'
const s:outBuffer = 'SQLOut'

let s:sqlBufNr = 0
function! sql#bufNr(bufnr = 0)
    if a:bufnr != 0
        let s:sqlBufNr = a:bufnr
    endif
    return s:sqlBufNr
endfunction

function! sql#new()
    if bufname('%')!='' || &modified
        tabnew
    endif
    set filetype=sql
    call sql#bufNr(bufnr())
    call sql#showCatalog()
endfunction

function! sql#showCatalog() " {{{1
    let catalogBufNr = bufnr('^'.s:catalogBuffer.'$')
    if catalogBufNr == -1
        let catalogBufNr = bufnr('^'.s:catalogBuffer.'$', 1)
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
