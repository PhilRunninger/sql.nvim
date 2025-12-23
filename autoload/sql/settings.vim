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
    \   '// Complete the user configuration below, and then remove these comments. For details,',
    \   '// see https://github.com/PhilRunninger/sql.nvim?tab=readme-ov-file#user-configuration.',
    \   '{',
    \   '    "sqlserver": {',
    \   '        "delimiter": ";",',
    \   '        "servers": {',
    \   '            "server1": {',
    \   '                "-U": "user",',
    \   '                "-P": "password"',
    \   '            },',
    \   '            "server2": {"order":1}',
    \   '        }',
    \   '    },',
    \   '    "postgres": {',
    \   '        "alignLimit": 0,',
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

function! sql#settings#servers() " {{{1
    let serverList = []
    let config = sql#settings#user()
    for p in keys(config)
        for s in keys(config[p].servers)
            let order = get(config[p].servers[s], 'order', v:numbermax)
            call add(serverList, [order, s.' ('.p.')'])
        endfor
    endfor
    call sort(serverList, {a,b -> a[1]==b[1] ? 0 : a[1]>b[1] ? 1 : -1})
    call sort(serverList, {a,b -> a[0]==b[0] ? 0 : a[0]>b[0] ? 1 : -1})
    return map(serverList, {_,v -> printf('%s %s', g:sql#unexplored, v[1])})
endfunction

function! sql#settings#serverInfo(platform, server) abort " {{{1
    return sql#settings#user()[a:platform].servers[a:server]
endfunction

function! sql#settings#alignLimit(platform) abort " {{{1
    return get(sql#settings#user()[a:platform], 'alignLimit',
    \          get(sql#settings#app()[a:platform], 'alignLimit', 5.0))
endfunction

function! sql#settings#delimiter(platform) abort " {{{1
    return get(sql#settings#user()[a:platform], 'delimiter', '|')
endfunction

function! sql#settings#actions(platform, type) abort " {{{1
    return sort(keys(get(sql#settings#app()[a:platform].actions, a:type, {})))
endfunction
