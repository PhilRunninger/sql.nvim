"  vim: foldmethod=marker

let s:connectionSeparator = ' ▶ '
let s:connectionStringPattern = '-- Connection: %s'.s:connectionSeparator.'%s'.s:connectionSeparator.'%s'
let s:connectionStringRegex = '^' . substitute(s:connectionStringPattern, '%s', '\\(.\\+\\)', 'g') . '$'

function! sql#connection#set(platform, server, database) " {{{1
    let bufnr = sql#bufnr()
    call nvim_buf_set_lines(bufnr, 0, empty(sql#connection#get())?0:1, 0, [printf(s:connectionStringPattern, a:platform, a:server, a:database)])
endfunction

function! sql#connection#get() " {{{1
    let bufnr = sql#bufnr()
    return matchlist(nvim_buf_get_lines(bufnr,0,1,0)[0], s:connectionStringRegex)[1:3]
endfunction
