let s:connectionSeparator = ' ▶ '
let s:connectionStringPattern = '-- Connection: %s'.s:connectionSeparator.'%s'.s:connectionSeparator.'%s'

function! sql#connection#regex()
    return '^' . substitute(s:connectionStringPattern, '%s', '\\(.\\+\\)', 'g') . '$'
endfunction

function! sql#connection#isSet() " {{{1
    return sql#platform() != '' && sql#server() != '' && sql#database() != ''
endfunction

function! sql#connection#set(platform, server, database) " {{{1
    let bufnr = sql#bufnr()
    call sql#platform(a:platform)
    call sql#server(a:server)
    call sql#database(a:database)

    let connection = nvim_buf_get_lines(bufnr,0,1,0)[0]
    if !empty(matchlist(connection, sql#connection#regex()))
        call nvim_buf_set_lines(bufnr,0,1,0,[])
    endif
    call nvim_buf_set_lines(bufnr,0,0,0,[printf(s:connectionStringPattern, a:platform, a:server, a:database)])
endfunction
