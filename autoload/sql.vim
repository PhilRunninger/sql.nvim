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
    if winnr == -1
        execute 'aboveleft sbuffer ' . bufnr
    else
        execute winnr . 'wincmd w'
    endif
endfunction

function! sql#showCatalog() abort " {{{1
    let bufnr = bufnr('⟪SQLCatalog⟫')
    if bufnr == -1
        let bufnr = bufnr('⟪SQLCatalog⟫', 1)

        let config = sql#settings#user()
        let serverList = []
        for p in keys(config)
            for s in keys(config[p].servers)
                let order = get(config[p].servers[s], 'order', v:numbermax)
                call add(serverList, [order, s.' ('.p.')'])
            endfor
        endfor
        call sort(serverList, {a,b -> a[1]==b[1] ? 0 : a[1]>b[1] ? 1 : -1})
        call sort(serverList, {a,b -> a[0]==b[0] ? 0 : a[0]>b[0] ? 1 : -1})
        call map(serverList, {_,v -> printf('%s %s', g:sql#unexplored, v[1])})

        call nvim_buf_set_lines(bufnr,0,-1,0,serverList)
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
