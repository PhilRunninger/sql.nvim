function! sql#settings#init(root)
    let s:root = a:root
    let s:tempFile = tempname()
    " let s:userConfigPath = stdpath('data') . '\sql.nvim\userconfig.json'
    let s:userConfigPath = s:root . '\.sql.json'
    if !filereadable(s:userConfigPath)
        call s:InitializeUserConfig()
    endif
endfunction

function s:InitializeUserConfig()
    " Using a list of strings for pretty formatting.
    let emptyConfig = [
    \   '{',
    \   '    "sqlserver": {',
    \   '        "cmdlineArgs": "",',
    \   '        "servers": [',
    \   '            "server1"',
    \   '        ]',
    \   '    },',
    \   '    "postgresql": {',
    \   '        "cmdlineArgs": "",',
    \   '        "servers": {',
    \   '            "server2": {"port": 5432, "databases": ["db2"]}',
    \   '        }',
    \   '    }',
    \   '}'
    \ ]
    if !isdirectory(fnamemodify(s:userConfigPath, ':p:h'))
        call mkdir(fnamemodify(s:userConfigPath, ':p:h'), 'p')
    endif
    call writefile(emptyConfig, s:userConfigPath)
    execute 'split '.s:userConfigPath
    call confirm('Complete the user settings file. Take note of its location for future reference.')
endfunction

function! sql#settings#root()
    return s:root
endfunction

function! sql#settings#tempFile()
    return s:tempFile
endfunction

function! sql#settings#app()
    return json_decode(readfile(s:root.'\config.json'))
endfunction

function! sql#settings#user()
    return json_decode(readfile(s:userConfigPath))
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

