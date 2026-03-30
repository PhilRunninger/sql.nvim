"  vim: foldmethod=marker

" Buffer-level key mappings, commands, and settings. {{{1
" Run script/paragraph/selection.
call nvim_buf_set_keymap(0, 'n', '<F5>',     ':call <SID>PrepAndRunQuery("file", 0)<CR>',                  {'silent':1})
call nvim_buf_set_keymap(0, 'n', '<S-F5>',   ':call <SID>PrepAndRunQuery("paragraph", 0)<CR>',             {'silent':1})
call nvim_buf_set_keymap(0, 'n', '<C-F5>',   ':call <SID>PrepAndRunQuery("block", 0)<CR>',                 {'silent':1})
call nvim_buf_set_keymap(0, 'v', '<F5>',     ':<C-U>call <SID>PrepAndRunQuery("selection", 0)<CR>',        {'silent':1})

" Run script/paragraph/selection with delimiter override.
call nvim_buf_set_keymap(0, 'n', '<M-F5>',   ':call <SID>PrepAndRunQuery("file", 1)<CR>',                  {'silent':1})
call nvim_buf_set_keymap(0, 'n', '<M-S-F5>', ':call <SID>PrepAndRunQuery("paragraph", 1)<CR>',             {'silent':1})
call nvim_buf_set_keymap(0, 'n', '<M-C-F5>', ':call <SID>PrepAndRunQuery("block", 1)<CR>',                 {'silent':1})
call nvim_buf_set_keymap(0, 'v', '<M-F5>',   ':<C-U>call <SID>PrepAndRunQuery("selection", 1)<CR>',        {'silent':1})

call nvim_buf_set_keymap(0, 'n', '<F3>',     ':call sql#search#start(expand("<cword>"))<CR>',              {'silent':1})
call nvim_buf_set_keymap(0, 'n', '<C-F3>',   ':call sql#search#start("")<CR>',                             {'silent':1})
call nvim_buf_set_keymap(0, 'n', '<F8>',     ':call sql#bufnr(bufnr())<CR>:call sql#showCatalog()<CR>',    {'silent':1})

setlocal statusline=%{%sql#statusline()%}

" Retreive and save state per file - saved connection info.   {{{1
let s:stateFilePath = stdpath('data') . '\sql.nvim\userstate.json'

function! s:getState()
    if !filereadable(s:stateFilePath)
        return []
    endif

    let allStates = sort(json_decode(readfile(s:stateFilePath)), {a, b -> b.accessed - a.accessed})
    let state = filter(copy(allStates), {_,v -> v.file == fnamemodify(bufname(bufnr()),':p')})
    if !empty(state)
        call sql#connection#set(state[0].plt, state[0].srv, state[0].db)
    endif

    return allStates
endfunction

function! s:saveState()
    let state = sql#connection#get()
    if empty(state)
        return
    endif

    let allStates = s:getState()
    let newState = {'accessed':localtime(), 'file':fnamemodify(bufname(bufnr()),':p'), 'plt':state[0], 'srv':state[1], 'db':state[2]}

    let idx = -1
    for i in range(len(allStates))
        if allStates[i].file == fnamemodify(bufname(bufnr()),':p')
            let idx = i
            break
        endif
    endfor

    if idx > -1
        call remove(allStates, idx)
    endif
    call insert(allStates, newState)

    if len(allStates) > 500
        call remove(allStates, 500, -1)
    endif

    call writefile([json_encode(allStates)], s:stateFilePath)
endfunction

call s:getState()
call s:saveState() " Updates 'accessed' if file is used and not saved again.

augroup sqlNvim
    autocmd!
    autocmd BufWrite <buffer> call s:saveState()
augroup END

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
    if !s:WriteTempFile(a:queryType)
        return
    endif

    let delimiter = sql#settings#delimiter(sql#connection#get()[0])
    if a:delimiterOverride
        let override = input('Enter a custom delimiter for this execution, default: ' . delimiter . '   ')
        if !empty(override)
            let delimiter = override
        endif
    endif
    call RunQuery(delimiter)
endfunction

function! RunQuery(delimiter) " {{{1
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
    elseif a:queryType == 'block'
        let block = s:FindBeginEndBlock()
        if empty(block)
            echo 'Cursor is not inside a BEGIN...END block.'
            return 0
        endif
        call writefile(getline(block[0], block[1]), sql#settings#tempFile())
    endif
    return 1
endfunction

function! s:FindBeginEndBlock() " {{{1
    let start = searchpair('\c\<BEGIN\>', '', '\c\<END\>', 'bcWn')
    let end = searchpair('\c\<BEGIN\>', '', '\c\<END\>', 'cWn')
    return (start == 0 || end == 0) ? [] : [start, end]
endfunction

function! s:RunQueryCallback(timer, job_id, data, event) " {{{1
    call timer_stop(a:timer)
    stopinsert
    let sqlOutBufNr = sql#sqlout#open(1)

    call nvim_buf_set_lines(sqlOutBufNr,0,-1,0,map(a:data, {_,v -> substitute(v, nr2char(13).'$', '', '')}))
    call sql#sqlout#format()
endfunction
