"  vim: foldmethod=marker

" Buffer-level key mappings, commands, and settings. {{{1
" Run script/paragraph/selection.
call nvim_buf_set_keymap(0, 'n', '<F5>',     ':call <SID>PrepAndRunQuery("file", 0)<CR>',                {'noremap':1, 'silent':1})
call nvim_buf_set_keymap(0, 'n', '<S-F5>',   ':call <SID>PrepAndRunQuery("paragraph", 0)<CR>',           {'noremap':1, 'silent':1})
call nvim_buf_set_keymap(0, 'n', '<C-F5>',   ':call <SID>PrepAndRunQuery("block", 0)<CR>',               {'noremap':1, 'silent':1})
call nvim_buf_set_keymap(0, 'v', '<F5>',     ':<C-U>call <SID>PrepAndRunQuery("selection", 0)<CR>',      {'noremap':1, 'silent':1})

" Run script/paragraph/selection with delimiter override.
call nvim_buf_set_keymap(0, 'n', '<M-F5>',   ':call <SID>PrepAndRunQuery("file", 1)<CR>',                {'noremap':1, 'silent':1})
call nvim_buf_set_keymap(0, 'n', '<M-S-F5>', ':call <SID>PrepAndRunQuery("paragraph", 1)<CR>',           {'noremap':1, 'silent':1})
call nvim_buf_set_keymap(0, 'n', '<M-C-F5>', ':call <SID>PrepAndRunQuery("block", 1)<CR>',               {'noremap':1, 'silent':1})
call nvim_buf_set_keymap(0, 'v', '<M-F5>',   ':<C-U>call <SID>PrepAndRunQuery("selection", 1)<CR>',      {'noremap':1, 'silent':1})

call nvim_buf_set_keymap(0, 'n', '<F3>',     ':call sql#search#openWindow()<CR>',                        {'noremap':1, 'silent':1})
call nvim_buf_set_keymap(0, 'n', '<F8>',     ':call sql#bufnr(bufnr())<CR>:call sql#catalog#show()<CR>', {'noremap':1, 'silent':1})

call sql#state#getConnection(bufnr())

" Virtual text that shows the connected server and database.   {{{1
call sql#settings#createHighlightGroups()

let s:ns = nvim_create_namespace('server_mark')

augroup SqlAugroupServerMark
    autocmd!
    autocmd CursorMoved,CursorMovedI,WinScrolled,VimResized,WinEnter,BufEnter,BufNew <buffer> call <SID>UpdateServerMark()
augroup END

function! s:UpdateServerMark() abort
    if &filetype !~? 'sql'
        return
    endif

    let conn = sql#state#getConnection(bufnr())
    if empty(conn)
        call nvim_buf_set_extmark(0, s:ns, line('w$') - 1, 0, {
            \   'id': 1,
            \   'virt_text': [[' ','Special'], ['Not Connected','WarningMsg']],
            \   'virt_text_pos': 'eol_right_align'
            \ })
        call nvim_buf_del_extmark(0, s:ns, 2)
        return
    endif

    let [server,database,highlightGroup] = [conn[1], conn[2], sql#settings#getHighlightGroup(conn[0],conn[1])[0]]
    if line('$') == 1
        call nvim_buf_set_extmark(0, s:ns, line('w$') - 1, 0, {
            \   'id': 1,
            \   'virt_text': [[' ','Special'], [printf('%s.%s',server,database),highlightGroup]],
            \   'virt_text_pos': 'eol_right_align'
            \ })
        call nvim_buf_del_extmark(0, s:ns, 2)
        return
    endif

    let length = max([len(server),len(database)])
    call nvim_buf_set_extmark(0, s:ns, line('w$') - 2, 0, {
        \   'id': 1,
        \   'virt_text': [[' ','Special'], [': ', 'Normal'], [printf('%*s',-length,server),highlightGroup]],
        \   'virt_text_pos': 'eol_right_align'
        \ })
    call nvim_buf_set_extmark(0, s:ns, line('w$') - 1, 0, {
        \   'id': 2,
        \   'virt_text': [[' ','Special'], [': ', 'Normal'], [printf('%*s',-length,database),highlightGroup]],
        \   'virt_text_pos': 'eol_right_align'
        \ })
endfunction

call s:UpdateServerMark()

function! s:PrepAndRunQuery(queryType, delimiterOverride) " {{{1
    if sql#query#isRunning()
        return
    endif

    call sql#bufnr(bufnr())
    let connection = sql#state#getConnection(bufnr())
    if empty(connection)
        call sql#catalog#show()
        echo 'SQL.nvim: Choose a connection from the catalog.'
        return
    endif
    if !s:WriteTempFile(a:queryType)
        return
    endif

    let delimiter = sql#settings#delimiter(connection[0])
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
    let [platform, server, database] = sql#state#getConnection(sql#bufnr())

    try
        let id = sql#query#run(function('s:RunQueryCallback', [timer]), a:delimiter, platform, server, database)
        call s:MapCancelKey(id)
    catch
        call timer_stop(timer)
        echoerr 'SQL.nvim: There was a problem running your query. Exception: ' . v:exception
    endtry
endfunction

function! s:MapCancelKey(id) " {{{1
    call nvim_buf_set_keymap(0, 'n', '<C-c>', ':call <SID>CancelQuery('.a:id.')<CR>', {'noremap':1, 'silent':1})
endfunction

function! s:CancelQuery(id)
    call jobstop(a:id)
    call nvim_buf_del_keymap(0, 'n', '<C-c>')
endfunction

function! s:UpdateStatus(startTime, bufNr, timer) " {{{1
    call nvim_buf_set_lines(a:bufNr,0,-1,0,[printf('Executing... %0.3f sec   Ctrl+C to quit.', reltimefloat(reltime(a:startTime)))])
endfunction

function! s:WriteTempFile(queryType) " {{{1
    if a:queryType == 'file'
        call writefile(getline(1,line('$')), sql#settings#tempFile())
    elseif a:queryType == 'paragraph'
        call writefile(getline(line("'{"),line("'}")), sql#settings#tempFile())
    elseif a:queryType == 'selection'
        silent normal! gv"zy
        call writefile(split(@z,'\n'), sql#settings#tempFile())
    elseif a:queryType == 'block'
        let block = s:FindBeginEndBlock()
        if empty(block)
            echo 'SQL.nvim: Cursor is not inside a BEGIN...END block.'
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

