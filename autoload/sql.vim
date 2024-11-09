const s:catalogBuffer = 'SQLCatalog'
const s:outBuffer = 'SQLOut'

let sql#bufNr = 0
let sql#outputBufNr = 0
let sql#catalogBufNr = 0

let sql#platform = ''
let sql#server = ''
let sql#database = ''

function! sql#new()
    if bufname('%')!='' || &modified
        tabnew
    endif
    set filetype=sql
    call sql#showCatalog()
endfunction

function! sql#showCatalog() " {{{1
    let sql#catalogBufNr = bufnr('^'.s:catalogBuffer.'$')
    if sql#catalogBufNr == -1
        let sql#catalogBufNr = bufnr('^'.s:catalogBuffer.'$', 1)
        let serverlist = sort(flatten(
        \   map(keys(sql#settings#user()),{_,p ->
        \       map(keys(sql#settings#user()[p].servers), {_,s -> '○ '.s.' ('.p.')'})})))
        call nvim_buf_set_lines(sql#catalogBufNr,0,-1,0,serverlist)
        keeppatterns silent g/^$/d
    endif
    let winnr = bufwinnr(sql#catalogBufNr)
    if winnr == -1
        call nvim_open_win(sql#catalogBufNr,1,{'width':40, 'noautocmd':1, 'style':'minimal', 'split':'right', 'win':-1})
        call nvim_set_option_value('filetype', 'sqlcatalog',    {'buf':sql#catalogBufNr})
    else
        execute winnr . 'wincmd w'
    endif
endfunction
