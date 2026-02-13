"  vim: foldmethod=marker

" Buffer-level key mappings, commands, and settings. {{{1
" Run script/paragraph/selection.
call nvim_buf_set_keymap(0, 'n', '<F5>',     ':call <SID>PrepAndRunQuery("file", 0)<CR>',                  {'silent':1})
call nvim_buf_set_keymap(0, 'n', '<S-F5>',   ':call <SID>PrepAndRunQuery("paragraph", 0)<CR>',             {'silent':1})
call nvim_buf_set_keymap(0, 'v', '<F5>',     ':<C-U>call <SID>PrepAndRunQuery("selection", 0)<CR>',        {'silent':1})

" Run script/paragraph/selection with delimiter override.
call nvim_buf_set_keymap(0, 'n', '<M-F5>',   ':call <SID>PrepAndRunQuery("file", 1)<CR>',                  {'silent':1})
call nvim_buf_set_keymap(0, 'n', '<M-S-F5>', ':call <SID>PrepAndRunQuery("paragraph", 1)<CR>',             {'silent':1})
call nvim_buf_set_keymap(0, 'v', '<M-F5>',   ':<C-U>call <SID>PrepAndRunQuery("selection", 1)<CR>',        {'silent':1})

call nvim_buf_set_keymap(0, 'n', '<F3>',     ':call <SID>FindObjectInCatalog(expand("<cword>"))<CR>',      {'silent':1})
call nvim_buf_set_keymap(0, 'n', '<C-F3>',   ':call <SID>FindObjectInCatalog("")<CR>',                     {'silent':1})
call nvim_buf_set_keymap(0, 'n', '<F8>',     ':call sql#bufnr(bufnr())<CR>:call sql#showCatalog()<CR>',    {'silent':1})

setlocal statusline=%l/%L\ %c%=%f%=%{empty(sql#connection#get())?'Not\ connected':join(sql#connection#get()[1:2],'.')}

function! s:FindObjectInCatalog(identifier) " {{{1
    if &filetype == 'sql'
        call sql#bufnr(bufnr())
    endif
    call sql#showCatalog()
    call sql#search#start(empty(a:identifier) ? '' : printf('\<%s\>', a:identifier))
endfunction

function! s:PrepAndRunQuery(queryType, delimiterOverride) " {{{1
    if sql#query#isRunning()
        return
    endif

    call sql#bufnr(bufnr())
    if empty(sql#connection#get())
        call sql#showCatalog()
        echo 'Choose a connection from the catalog.'
        return
    endif

    call sql#bufnr(bufnr())
    call s:WriteTempFile(a:queryType)

    let delimiter = sql#settings#delimiter(sql#connection#get()[0])
    if a:delimiterOverride
        let override = input('Enter a custom delimiter for this execution, default: ' . delimiter . '   ')
        if !empty(override)
            let delimiter = override
        endif
    endif
    call s:RunQuery(delimiter)
endfunction

function! s:RunQuery(delimiter) " {{{1
    let sqlOutBufNr = sql#sqlout#open(0)
    let timer = timer_start(100, function('s:UpdateStatus',[reltime(), sqlOutBufNr]), {'repeat': -1})

    call nvim_buf_set_var(sqlOutBufNr, 'csv_delimiter', a:delimiter)
    call nvim_buf_set_var(sqlOutBufNr, 'delimiter', a:delimiter)
    let [platform, server, database] = sql#connection#get()

    try
        let id = sql#query#run(function('s:RunQueryCallback', [timer]), a:delimiter, platform, server, database)
        call s:MapCancelKey(id)
    catch
        call timer_stop(timer)
        echoerr "Your query couldn't be run. Check this file's connection string in line 1 for errors."
    endtry
endfunction

function! s:MapCancelKey(id) " {{{1
    execute 'nnoremap <silent> <buffer> <C-c> :call <SID>CancelQuery('.a:id.')<CR>'
endfunction

function! s:CancelQuery(id)
    call jobstop(a:id)
    nunmap <buffer> <C-c>
endfunction

function! s:UpdateStatus(startTime, bufNr, timer) " {{{1
    call nvim_buf_set_lines(a:bufNr,0,-1,0,[printf('Executing... %0.3f sec   Ctrl+C to quit.', reltimefloat(reltime(a:startTime)))])
endfunction

function! s:WriteTempFile(queryType) " {{{1
    if a:queryType == 'file'
        call writefile(getline(2,line('$')), sql#settings#tempFile())
    elseif a:queryType == 'paragraph'
        call writefile(getline(line("'{"),line("'}")), sql#settings#tempFile())
    elseif a:queryType == 'selection'
        silent normal! gv"zy
        call writefile(split(@z,'\n'), sql#settings#tempFile())
    endif
endfunction

function! s:RunQueryCallback(timer, job_id, data, event) " {{{1
    call timer_stop(a:timer)
    stopinsert
    let sqlOutBufNr = sql#sqlout#open(1)

    call nvim_buf_set_lines(sqlOutBufNr,0,-1,0,map(a:data, {_,v -> substitute(v, nr2char(13).'$', '', '')}))
    call sql#sqlout#format()
endfunction
