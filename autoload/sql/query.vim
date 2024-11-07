function! sql#query#run(callback, platform, server, database, type='', action='', actionValues={})
    let cmdline = s:CommandLine(a:platform, a:server, a:database, a:type, a:action, a:actionValues)
    return jobstart(cmdline, {'stdout_buffered': v:true, 'on_stdout': a:callback, 'on_stderr': function('s:StdErr')})
endfunction

function! s:StdErr(job_id, data, event)
    call foreach(filter(a:data, {_,v -> v != ''}), 'echoerr v:val')
endfunction

function! s:CommandLine(platform, server, database, type, action, actionValues) " {{{1
    let cmdline = sql#settings#app()[a:platform].cmdline
    let cmdline .= ' '.sql#settings#user()[a:platform].cmdlineArgs
    if a:action != ''
        let cmdline .= ' '.sql#settings#app()[a:platform].actions.cmdlineArgs
        let file = sql#settings#root().'\'.a:platform.'\'.sql#settings#app()[a:platform].actions[a:type][a:action]
        let cmdline = substitute(cmdline, '<file>', escape(file, '\'), '')
    endif
    let cmdline = substitute(cmdline, '<svr>', escape(a:server, '\'), '')
    let cmdline = substitute(cmdline, '<db>', a:database, '')
    let cmdline = substitute(cmdline, '<file>', escape(sql#settings#tempFile(), '\'), '')

    let paramValues = extend(copy(sql#settings#serverInfo(a:platform, a:server)), a:actionValues, 'force')
    let parm = matchstr(cmdline, '<\w\{-}>')
    while parm != ''
        let cmdline = substitute(cmdline, parm, get(paramValues, parm[1:-2], ''), '')
        let parm = matchstr(cmdline, '<\w\{-}>')
    endwhile

    return cmdline
endfunction
