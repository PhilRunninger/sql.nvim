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
    let cmdline = sql#settings#app()[a:platform].executable
    let cmdline .= ' '.s:formatArgString(sql#settings#app()[a:platform].args)
    let cmdline .= ' '.s:formatArgString(sql#settings#serverInfo(a:platform,a:server))
    let cmdline .= empty(a:action) ? '' : ' '.s:formatArgString(sql#settings#app()[a:platform].actions.args)

    let file = empty(a:action) ?
          \ sql#settings#tempFile() :
          \ sql#settings#root().'\'.a:platform.'\'.sql#settings#app()[a:platform].actions[a:type][a:action]
    let cmdline = substitute(cmdline, '<file>', escape(file, '\'), '')
    let cmdline = substitute(cmdline, '<server>', escape(a:server, '\'), '')
    let cmdline = substitute(cmdline, '<database>', a:database, '')
    let cmdline = substitute(cmdline, '<delimiter>', sql#settings#delimiter(a:platform), '')

    let parm = matchstr(cmdline, '<\w\{-}>')
    while parm != ''
        let cmdline = substitute(cmdline, parm, get(a:actionValues, parm[1:-2], ''), '')
        let parm = matchstr(cmdline, '<\w\{-}>')
    endwhile

    return cmdline
endfunction

function! s:formatArgString(args) abort " {{{1
    return join(map(filter(keys(a:args),{_,v -> v != 'order'}), {_,v -> v.' '.(a:args[v]==v:null ? '' : a:args[v])}), ' ')
endfunction
