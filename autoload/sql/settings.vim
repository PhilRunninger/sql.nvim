"  vim: foldmethod=marker

function! sql#settings#init(root) " {{{1
    let s:root = a:root
    let s:tempFile = tempname()
    let s:userConfigPath = stdpath('data') . '\sql.nvim\userconfig.json'
    call s:InitializeUserConfig()
endfunction

function! s:InitializeUserConfig() " {{{1
    if filereadable(s:userConfigPath)
        return
    endif

    if !isdirectory(fnamemodify(s:userConfigPath, ':p:h'))
        call mkdir(fnamemodify(s:userConfigPath, ':p:h'), 'p')
    endif
    call filecopy(s:root.'\userconfig.json', s:userConfigPath)
    call sql#settings#edit()
    echohl WarningMsg
    echomsg 'A user config file has been created for you. Use `:SQL config` to add your DB server connections and settings.'
    echohl None
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
        let userSettigns = json_decode(readfile(s:userConfigPath))
        if has_key(userSettigns, '_comment')
            call remove(userSettigns, '_comment')
        endif
        return userSettigns
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

function! sql#settings#marks(platform, server) abort " {{{1
    return get(sql#settings#serverInfo(a:platform, a:server), 'marks', {})
endfunction

function! sql#settings#args(platform, server) abort " {{{1
    let info = sql#settings#serverInfo(a:platform, a:server)
    if has_key(info, 'args')
        return info.args
    endif

    " For backward compatibility with older config files, if args is not
    " defined, return the whole server info minus the order and marks keys.
    for k in ['order','marks']
        if has_key(info, k)
            call remove(info, k)
        endif
    endfor
    return info
endfunction

function! sql#settings#alignLimit(platform) abort " {{{1
    return get(sql#settings#user()[a:platform], 'alignLimit',
    \          get(sql#settings#app()[a:platform], 'alignLimit', 5.0))
endfunction

function! sql#settings#delimiter(platform) abort " {{{1
    return get(sql#settings#user()[a:platform], 'delimiter', '|')
endfunction

function! sql#settings#actions(platform, type) abort " {{{1
    let actionList = values(map(sql#settings#app()['sqlserver'].actions[a:type], {k,v -> [v.order, k]}))
    call sort(actionList, {a,b -> a[0]==b[0] ? 0 : a[0]>b[0] ? 1 : -1})
    return map(actionList, {_,v -> v[1]})
endfunction
