
function! sql#settings#init(root)
    let s:root = a:root
    let s:tempFile = tempname()
endfunction

function! sql#settings#root()
    return s:root
endfunction

function! sql#settings#tempFile()
    return s:tempFile
endfunction

function! sql#settings#app()
    return json_decode(readfile(s:root.'\sql.json'))
endfunction

function! sql#settings#user()
    return json_decode(readfile(s:root.'\.sql.json'))
endfunction

function! sql#settings#serverInfo()
    return sql#settings#user()[b:platform].servers[b:server]
endfunction

function! sql#settings#alignTimeLimit()
    return get(sql#settings#user()[b:platform], 'alignTimeLimit',
    \          get(sql#settings#app()[b:platform], 'alignTimeLimit', 5.0))
endfunction

function! sql#settings#doAlign()
    return get(sql#settings#user()[b:platform], 'doAlign',
    \          get(sql#settings#app()[b:platform], 'doAlign', 1))
endfunction

function! sql#settings#actions(type)
    return sort(keys(sql#settings#app()[b:platform].actions[a:type]))
endfunction

