"  vim: foldmethod=marker

function! sql#query#run(callback, platform, server, database, type='', action='', actionValues={}) " {{{1
    let cmdline = s:commandLine(a:platform, a:server, a:database, a:type, a:action, a:actionValues)
    return jobstart(cmdline, {'stdout_buffered': v:true, 'on_stdout': a:callback, 'on_stderr': function('s:stdErr')})
endfunction

function! s:stdErr(job_id, data, event) " {{{1
    if empty(filter(copy(a:data),{_,v -> !empty(v)}))
        return
    endif

    echoerr join(a:data, nr2char(10))
endfunction

function! s:commandLine(platform, server, database, type, action, actionValues) " {{{1
    let cmdline = sql#settings#app()[a:platform].executable
    let cmdline .= ' '.s:formatArgString(sql#settings#app()[a:platform].args)
    let cmdline .= ' '.s:formatArgString(sql#settings#serverInfo(a:platform,a:server))
    let cmdline .= empty(a:action) ? '' : ' '.s:formatArgString(sql#settings#app()[a:platform].actions.args)

    let cmdline = substitute(cmdline, '<server>', escape(substitute(a:server,'^! ','',''), '\'), '')
    let cmdline = substitute(cmdline, '<database>', a:database, '')
    let file = empty(a:action) ?
          \ sql#settings#tempFile() :
          \ sql#settings#root().'\'.a:platform.'\'.sql#settings#app()[a:platform].actions[a:type][a:action]
    let cmdline = substitute(cmdline, '<file>', escape(file, '\'), '')

    let paramValues = extend(copy(sql#settings#serverInfo(a:platform, a:server)), a:actionValues, 'force')
    let parm = matchstr(cmdline, '<\w\{-}>')
    while parm != ''
        let cmdline = substitute(cmdline, parm, get(paramValues, parm[1:-2], ''), '')
        let parm = matchstr(cmdline, '<\w\{-}>')
    endwhile

    return cmdline
endfunction

function! s:formatArgString(args) " {{{1
    return join(map(keys(a:args), {_,v -> v.' '.(a:args[v]==v:null ? '' : a:args[v])}), ' ')
endfunction
