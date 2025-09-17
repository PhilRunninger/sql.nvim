"  vim: foldmethod=marker

function! sql#query#isRunning() " {{{1
    return exists('s:job_id')
endfunction

function! sql#query#run(callback, platform, server, database, type='', action='', actionValues={}) abort " {{{1
    if !sql#query#isRunning()
        let cmdline = s:commandLine(a:platform, a:server, a:database, a:type, a:action, a:actionValues)
        let s:job_id = jobstart(cmdline, #{stdout_buffered: v:true, stderr_buffered: v:true, on_stdout: function('s:on_stdout', [a:callback]), on_stderr: function('s:on_stderr'), on_exit: function('s:on_exit')})
    endif
    return s:job_id
endfunction

function! s:on_stdout(callback, job_id, data, event) " {{{1
    call a:callback(a:job_id, a:data, a:event)
endfunction

function! s:on_stderr(job_id, data, event) " {{{1
    if empty(filter(copy(a:data),{_,v -> !empty(v)}))
        return
    endif

    echoerr join(a:data, nr2char(10))
endfunction

function! s:on_exit(job_id, data, event) " {{{1
    unlet s:job_id
endfunction

function! s:commandLine(platform, server, database, type, action, actionValues) abort " {{{1
    let actionValues = {
        \ 'file':      escape(empty(a:action) ?
            \ sql#settings#tempFile() :
            \ printf('%s\%s\%s', sql#settings#root(), a:platform, sql#settings#app()[a:platform].actions[a:type][a:action]), '\'),
        \ 'server':    escape(a:server,'\'),
        \ 'database':  escape(a:database,'\'),
        \ 'delimiter': sql#settings#delimiter(a:platform)
    \ }
    let actionValues = extend(a:actionValues, actionValues, 'force')

    let cmdline = sql#settings#app()[a:platform].executable
    let cmdline .= ' '.s:formatArgString(sql#settings#app()[a:platform].args, actionValues)
    let cmdline .= ' '.s:formatArgString(sql#settings#serverInfo(a:platform,a:server), actionValues)
    let cmdline .= empty(a:action) ? '' : ' '.s:formatArgString(sql#settings#app()[a:platform].actions.args, actionValues)

    return cmdline
endfunction

function! s:formatArgString(args, actionValues={}) abort " {{{1
    let args = filter(a:args,{k,_ -> k != 'order'})

    for k in keys(args)
        let parm = matchstr(args[k], '<\w\{-}>')
        if empty(parm)
            continue
        endif
        if has_key(a:actionValues, parm[1:-2])
            let args[k] = substitute(args[k], parm, get(a:actionValues, parm[1:-2], ''), 'g')
            continue
        endif
        call remove(args, k)
    endfor

    return join(values(map(args, {k, v -> v == v:null ? k : k.' '.v})), ' ')
endfunction
