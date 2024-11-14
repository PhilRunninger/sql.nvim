"  vim: foldmethod=marker

function! sql#settings#init(root)
    let s:root = a:root
    let s:tempFile = tempname()
    let s:userConfigPath = stdpath('data') . '\sql.nvim\userconfig.json'
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

function! sql#settings#serverInfo(platform, server)
    return sql#settings#user()[a:platform].servers[a:server]
endfunction

function! sql#settings#alignTimeLimit(platform)
    return get(sql#settings#user()[a:platform], 'alignTimeLimit',
    \          get(sql#settings#app()[a:platform], 'alignTimeLimit', 5.0))
endfunction

function! sql#settings#doAlign(platform)
    return get(sql#settings#user()[a:platform], 'doAlign',
    \          get(sql#settings#app()[a:platform], 'doAlign', 1))
endfunction

function! sql#settings#actions(platform, type)
    return sort(keys(sql#settings#app()[a:platform].actions[a:type]))
endfunction

