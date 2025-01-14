"  vim: foldmethod=marker

" These are essentially the global variables for this plugin. " {{{1
let s:bufnr = 0
function! sql#bufnr(bufnr = 0)
    let s:bufnr = a:bufnr == 0 ? s:bufnr : a:bufnr
    return s:bufnr
endfunction

function! sql#showSQL() " {{{1
    let bufnr = sql#bufnr()
    if !bufexists(bufnr)
        if bufname('%') != '' || &modified
            aboveleft new
        endif
        set filetype=sql
        let bufnr = sql#bufnr(bufnr())
    endif

    let winnr = bufwinnr(bufnr)
    if winnr == -1
        execute 'aboveleft sbuffer ' . bufnr
    else
        execute winnr . 'wincmd w'
    endif
endfunction

function! sql#showCatalog() " {{{1
    let bufnr = bufnr('⟪SQLCatalog⟫')
    if bufnr == -1
        let bufnr = bufnr('⟪SQLCatalog⟫', 1)
        let serverlist = sort(flatten(
        \   map(keys(sql#settings#user()),{_,p ->
        \       map(keys(sql#settings#user()[p].servers), {_,s -> '○ '.s.' ('.p.')'})})))
        call nvim_buf_set_lines(bufnr,0,-1,0,serverlist)
        keeppatterns silent g/^$/d
    endif
    let winnr = bufwinnr(bufnr)
    if winnr == -1
        call nvim_open_win(bufnr,1,{'width':40, 'noautocmd':1, 'style':'minimal', 'split':'right', 'win':-1})
        call nvim_set_option_value('filetype', 'sqlcatalog',    {'buf':bufnr})
    else
        execute winnr . 'wincmd w'
    endif
endfunction

"  vim: foldmethod=marker
