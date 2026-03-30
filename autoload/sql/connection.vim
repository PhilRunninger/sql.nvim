"  vim: foldmethod=marker

function! sql#connection#set(platform, server, database) " {{{1
    let bufnr = sql#bufnr()
    call nvim_buf_set_var(bufnr, 'platform', a:platform)
    call nvim_buf_set_var(bufnr, 'server',   a:server)
    call nvim_buf_set_var(bufnr, 'database', a:database)
    redrawstatus!
endfunction

function! sql#connection#get() " {{{1
    try
        let bufnr = sql#bufnr()
        return [
            \ nvim_buf_get_var(bufnr, 'platform'),
            \ nvim_buf_get_var(bufnr, 'server'),
            \ nvim_buf_get_var(bufnr, 'database')
            \ ]
    catch
        return []
    endtry
endfunction
