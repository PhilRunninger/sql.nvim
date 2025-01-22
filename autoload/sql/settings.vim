"  vim: foldmethod=marker

function! sql#settings#init(root) " {{{1
    let s:root = a:root
    let s:tempFile = tempname()
    let s:userConfigPath = stdpath('data') . '\sql.nvim\userconfig.json'
    if !filereadable(s:userConfigPath)
        call s:InitializeUserConfig()
    endif
endfunction

function! s:InitializeUserConfig() " {{{1
    " Using a list of strings for pretty formatting.
    let sampleConfig = [
    \   '// Complete the user configuration below, and then remove this line.',
    \   '{',
    \   '    "sqlserver": {',
    \   '        "servers": {',
    \   '            "server1": {',
    \   '                "-U": "user",',
    \   '                "-P": "password"',
    \   '            },',
    \   '            "server2": {}',
    \   '        }',
    \   '    },',
    \   '    "postgres": {',
    \   '        "alignThreshold": 0.0,',
    \   '        "servers": {',
    \   '            "server3": {',
    \   '                "-p": 5432',
    \   '            }',
    \   '        }',
    \   '    }',
    \   '}'
    \ ]

    if !isdirectory(fnamemodify(s:userConfigPath, ':p:h'))
        call mkdir(fnamemodify(s:userConfigPath, ':p:h'), 'p')
    endif
    call writefile(sampleConfig, s:userConfigPath)
endfunction

function! sql#settings#edit() " {{{1
    execute 'split '.s:userConfigPath
endfunction

function! sql#settings#root() " {{{1
    return s:root
endfunction

function! sql#settings#tempFile() " {{{1
    return s:tempFile
endfunction

function! sql#settings#app() " {{{1
    return json_decode(readfile(s:root.'\config.json'))
endfunction

function! sql#settings#user() " {{{1
    try
        return json_decode(readfile(s:userConfigPath))
    catch
        call sql#settings#edit()
        throw 'sql.nvim: Invalid User Config'
    endtry
endfunction

function! sql#settings#serverInfo(platform, server) abort " {{{1
    return sql#settings#user()[a:platform].servers[a:server]
endfunction

function! sql#settings#alignThreshold(platform) abort " {{{1
    return get(sql#settings#user()[a:platform], 'alignThreshold',
    \          get(sql#settings#app()[a:platform], 'alignThreshold', 5.0))
endfunction

function! sql#settings#actions(platform, type) abort " {{{1
    return sort(keys(get(sql#settings#app()[a:platform].actions, a:type, {})))
endfunction
