let s:connectionSeparator = ' ▶ '
let s:connectionStringPattern = '-- Connection: %s'.s:connectionSeparator.'%s'.s:connectionSeparator.'%s'

function sql#connection#regex()
    return '^' . substitute(s:connectionStringPattern, '%s', '\\(.\\+\\)', 'g') . '$'
endfunction


function! sql#connection#isSet() " {{{1
    return get(b:, 'platform', '') != '' && get(b:, 'server', '') != '' && get(b:, 'database', '') != ''
endfunction

function! sql#connection#set() " {{{1
    try
        let serverlist = sort(flatten(map(
        \   keys(sql#settings#user()),
        \   {_,platform -> map(
        \       keys(sql#settings#user()[platform].servers),
        \       {_,server -> map(
        \           copy(sql#settings#user()[platform].servers[server].databases),
        \           {_,database -> platform . s:connectionSeparator . server . s:connectionSeparator . database })
        \       })
        \   })))

        let connection = sql#chooser#choose('Connecting to:', serverlist)
        let [b:platform, b:server,b:database] = split(connection, s:connectionSeparator)

        if !empty(matchlist(getline(1), sql#connection#regex()))
            silent normal! ggdd _
        endif
        silent call append(0, printf(s:connectionStringPattern, b:platform, b:server, b:database))
        redraw!
        return sql#connection#isSet()
    catch /.*/
        echo v:exception
        return 0
    endtry
endfunction

