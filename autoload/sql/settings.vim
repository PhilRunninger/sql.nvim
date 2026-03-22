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
endfunction

function! s:ValidateUserConfig() " {{{1
    let userSettings = json_decode(readfile(s:userConfigPath))
    call s:removeComments(userSettings)

    if type(userSettings) != v:t_dict
        throw 'User config must be a JSON object'
    endif
    call s:validKeys(userSettings, ['sqlserver', 'postgres'], 'Invalid platform: %s')

    for p in keys(userSettings)
        call s:isType(userSettings, p, v:false, [v:t_dict], '%s must be an object')

        call s:validKeys(userSettings[p], ['delimiter', 'alignLimit', 'servers'], 'Unsupported platform attribute: '.p.'.%s')
        call s:isType(userSettings[p], 'delimiter', v:false, [v:t_string], p . '.%s must be a string')
        call s:isType(userSettings[p], 'alignLimit', v:false, [v:t_number, v:t_float], p . '.%s must be a number')
        call s:isType(userSettings[p], 'servers', v:true, [v:t_dict], p . '.%s is required and must be an object')

        for s in keys(userSettings[p].servers)
            call s:isType(userSettings[p].servers, s, v:false, [v:t_dict], p . '.servers.%s must be an object')
            call s:validKeys(userSettings[p].servers[s], ['order', 'marks', 'args'], 'Consider moving '.p.'.servers.'.s.'.%s to '.p.'.servers.'.s.'.args')
            call s:isType(userSettings[p].servers[s], 'order', v:false, [v:t_number], p . '.servers.'.s.'.%s must be an integer')
            call s:isType(userSettings[p].servers[s], 'marks', v:false, [v:t_dict], p . '.servers.'.s.'.%s must be an object')
            call s:isType(userSettings[p].servers[s], 'args', v:false, [v:t_dict], p . '.servers.'.s.'.%s must be an object')
        endfor
    endfor

    return userSettings
endfunction

function! s:removeComments(obj) " {{{2
    if type(a:obj) == v:t_dict
        if has_key(a:obj, '_comment_')
            call remove(a:obj, '_comment_')
        endif
        for k in keys(a:obj)
            call s:removeComments(a:obj[k])
        endfor
    elseif type(a:obj) == v:t_list
        for i in range(len(a:obj))
            call s:removeComments(a:obj[i])
        endfor
    endif
endfunction

function! s:isType(obj, key, required, validTypes, msg) " {{{2
    if !has_key(a:obj, a:key)
        if a:required
            throw printf(a:msg, a:key)
        else
            return
        endif
    endif

    if index(a:validTypes, type(a:obj[a:key])) == -1
        throw printf(a:msg, a:key)
    endif
endfunction

function! s:validKeys(obj, allowed, msg) " {{{2
    for k in keys(a:obj)
        if index(a:allowed, k) == -1
            throw printf(a:msg, k)
        endif
    endfor
endfunction

function! sql#settings#edit() " {{{1
    call s:InitializeUserConfig()

    let winnr = bufwinnr(bufnr(s:userConfigPath))
    if winnr == -1
        execute 'split '.s:userConfigPath
    else
        execute winnr.'wincmd w'
    endif
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

function! sql#settings#user() abort " {{{1
    try
        return s:ValidateUserConfig()
    catch
        call sql#settings#edit()
        echohl WarningMsg
        echomsg 'Error in sql.nvim user config: '.v:exception
        echohl None
        return {}
    endtry
endfunction

function! sql#settings#servers() abort " {{{1
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
    return get(sql#settings#serverInfo(a:platform, a:server), 'args', {})
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
