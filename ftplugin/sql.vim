"  vim: foldmethod=marker

function! s:PrepAndRunQuery(queryType) " {{{1
    if sql#query#isRunning()
        return
    endif

    call sql#bufnr(bufnr())
    if !sql#connection#isSet()
        call sql#showCatalog()
        echo 'Choose a connection from the catalog.'
        return
    endif
    call s:WriteTempFile(a:queryType)
    call s:RunQuery()
endfunction

function! s:RunQuery() " {{{1
    let sqlOutBufNr = s:OpenSQLOutWindow(0)
    call s:UpdateStatus(reltime(), sqlOutBufNr, v:null)
    let timer = timer_start(1000, function('s:UpdateStatus',[reltime(), sqlOutBufNr]), {'repeat': -1})

    let id = sql#query#run(function('s:RunQueryCallback', [timer]), sql#platform(), sql#server(), sql#database())
    call s:MapCancelKey(id)
endfunction

function! s:MapCancelKey(id) " {{{1
    execute 'nnoremap <buffer> <C-c> :call <SID>CancelQuery('.a:id.')<CR>'
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
        let start = empty(matchlist(getline(1), sql#connection#regex())) ? 1 : 2
        call writefile(getline(start,line('$')), sql#settings#tempFile())
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
    let sqlOutBufNr = s:OpenSQLOutWindow(1)
    call nvim_buf_set_lines(sqlOutBufNr,0,-1,0,map(a:data, {_,v -> substitute(v, nr2char(13).'$', '', '')}))
    call s:FormatSQLOut()
endfunction

function! s:OpenSQLOutWindow(enter) " {{{1
    let bufnr = bufnr('⟪SQLOut⟫', 1)
    let winnr = bufwinnr('⟪SQLOut⟫')
    if winnr == -1
        let handle = nvim_open_win(bufnr, a:enter, {'noautocmd':1, 'split':'below'})
        call nvim_set_option_value('buftype',  'nofile', {'buf':bufnr})
        call nvim_set_option_value('filetype', 'csv',    {'buf':bufnr})
        call nvim_set_option_value('swapfile', v:false,  {'buf':bufnr})
        call nvim_set_option_value('wrap',     v:false,  {'win':handle})
        call nvim_buf_set_keymap(bufnr, 'n', '<F5>', ':call <SID>RunQuery()<CR>', {'noremap':1})
        call nvim_buf_set_keymap(bufnr, 'n', '<F8>', ':call sql#showSQL()<CR>', {'noremap':1})
    elseif a:enter
        execute winnr . ' wincmd w'
    endif
    return bufnr
endfunction

function! s:FormatSQLOut() " {{{1
    silent execute 'keeppatterns %s/^\s\+$//e'
    silent execute 'keeppatterns %s/^\s*\((\d\+ rows\?\( affected\)\?)\)/\r\1\r/e'

    call s:JoinLines()
    call s:AlignColumns()

    silent execute 'keeppatterns g/^$\n^$/d'
    silent execute 'keeppatterns g/^$\n^\s*(\d\+ rows\?\( affected\)\?)/d'

    normal gg
endfunction

function! s:JoinLines() " {{{1
    let startRow = 1
    while startRow < line('$')
        call cursor(startRow,1)
        let endRow = search('^\s*(\d\+ rows\?\( affected\)\?)', 'cW') - 1
        if endRow == -1
            break
        endif
        let required = count(getline(startRow), s:colSeparator)
        let startRow += 2
        while startRow < endRow && required > 0
            let rows = 0
            let count = count(getline(startRow), s:colSeparator)
            let countNext = count(getline(startRow+1), s:colSeparator)
            while startRow + rows < endRow && (count < required || countNext == 0)
                let rows += 1
                let count += count(getline(startRow + rows), s:colSeparator)
                let countNext = count(getline(startRow + rows + 1), s:colSeparator)
            endwhile
            if rows > 0
                execute startRow.','.(startRow + rows).'join'
                let endRow -= rows
            else
                let startRow += 1
            endif
        endwhile
        let startRow = endRow + 3
    endwhile
    silent execute 'keeppatterns %s/'.nr2char(13).'$//e'
endfunction

function! s:AlignColumns() " {{{1
    if exists(':EasyAlign') && sql#settings#alignThreshold(sql#platform()) > 0
        normal! gg
        let startRow = search('^.\+$','cW')
        while startRow > 0
            let columns = count(getline(startRow), s:colSeparator) + 1
            let endRow = line("'}") - (line("'}") != line("$"))
            let rows = endRow - startRow - 1
            " These coefficients were derived from an experiment I did with
            " tables as long as 10000 rows (2 columns), as wide as 2048
            " columns (10 rows), and various sizes in between.
            let timeEstimate = 0.000299808*rows*columns + 0.014503037*columns
            if timeEstimate <= sql#settings#alignThreshold(sql#platform())
                silent execute startRow . ',' . endRow . 'EasyAlign */'.s:colSeparator.'/'
            endif
            normal! }
            let startRow = search('^.\+$','W')
        endwhile
    endif

    if exists(':CSVInit')
        let b:delimiter = s:colSeparator
        let b:csv_headerline = 0
        CSVInit!
    endif
endfunction

" Start Here {{{1
call sql#settings#init(expand('<sfile>:p:h:h'))

let s:colSeparator = ';'  " Make sure SQL output separator matches this.

let connectionParts = matchlist(getline(1), sql#connection#regex())
if !empty(connectionParts)
    call sql#platform(connectionParts[1])
    call sql#server(connectionParts[2])
    call sql#database(connectionParts[3])
endif

call nvim_buf_set_keymap(0, 'n', '<F5>',   ':call <SID>PrepAndRunQuery("file")<CR>',                  {'silent':1})
call nvim_buf_set_keymap(0, 'n', '<S-F5>', ':call <SID>PrepAndRunQuery("paragraph")<CR>',             {'silent':1})
call nvim_buf_set_keymap(0, 'v', '<F5>',   ':<C-U>call <SID>PrepAndRunQuery("selection")<CR>',        {'silent':1})
call nvim_buf_set_keymap(0, 'n', '<F8>',   ':call sql#bufnr(bufnr())<CR>:call sql#showCatalog()<CR>', {'silent':1})
