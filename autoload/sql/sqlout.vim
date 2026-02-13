let s:bufferName = '⟪SQLOut⟫'

function! sql#sqlout#open(enter) " {{{1
    let bufnr = bufnr(s:bufferName)
    if bufnr == -1
        let bufnr = bufnr(s:bufferName, 1)
        call nvim_set_option_value('buftype',  'nofile', {'buf':bufnr})
        call nvim_set_option_value('filetype', 'csv',    {'buf':bufnr})
        call nvim_set_option_value('swapfile', v:false,  {'buf':bufnr})

        call nvim_buf_set_keymap(bufnr, 'n', '<F3>',   ':call <SID>FindObjectInCatalog(expand("<cword>"))<CR>', {'silent':1})
        call nvim_buf_set_keymap(bufnr, 'n', '<C-F3>', ':call <SID>FindObjectInCatalog("")<CR>', {'silent':1})
        call nvim_buf_set_keymap(bufnr, 'n', '<F5>', ' :call <SID>RunQuery(b:delimiter)<CR>', {'noremap':1, 'silent':1})
        call nvim_buf_set_keymap(bufnr, 'n', '<F8>',  ':call sql#showSQL()<CR>', {'noremap':1, 'silent':1})
    endif

    let winnr = bufwinnr(s:bufferName)
    if winnr == -1
        let handle = nvim_open_win(bufnr, a:enter, {'noautocmd':1, 'split':'below'})
        call nvim_set_option_value('wrap',      v:false, {'win':handle})
        call nvim_set_option_value('winfixbuf', v:true,  {'win':handle})
    elseif a:enter
        execute winnr . ' wincmd w'
    endif
    return bufnr
endfunction

function! sql#sqlout#format() " {{{1
    call s:JoinLines()
    call s:AlignColumns()
    normal! gg

    syntax clear
    source $VIMRUNTIME/**/syntax/csv.vim
endfunction

function! s:JoinLines() " {{{1
    let bottomBorder = '\(^$\|^\s*(\d\+ rows\?\( affected\)\?)\)'
    let topBorder = '^\(-\+\s*' . b:delimiter . '\s*\)\+-\+$'
    normal! gg
    let startRow = search(topBorder,'cW') - 1
    while startRow > -1
        call cursor(startRow,1)
        let endRow = search(bottomBorder, 'cW') - 1
        if endRow == -1
            break
        endif
        let required = count(getline(startRow), b:delimiter)
        let startRow += 2
        while startRow < endRow && required > 0
            let rows = 0
            let count = count(getline(startRow), b:delimiter)
            let countNext = count(getline(startRow+1), b:delimiter)
            while startRow + rows < endRow && (count < required || countNext == 0)
                let rows += 1
                let count += count(getline(startRow + rows), b:delimiter)
                let countNext = count(getline(startRow + rows + 1), b:delimiter)
            endwhile
            if rows > 0
                execute startRow.','.(startRow + rows).'join'
                let endRow -= rows
            else
                let startRow += 1
            endif
        endwhile
        call cursor(endRow,1)
        let startRow = search(topBorder,'cW') - 1
    endwhile
    silent execute 'keeppatterns g/^$/d'
    silent execute 'keeppatterns %s/^\s*\zs(\d\+ rows\?\( affected\)\?)\ze/&\r/e'
endfunction

function! s:AlignColumns() " {{{1
    if exists('*v:lua.MiniAlign.setup')
        call s:MiniAlign()
    elseif exists(':EasyAlign')
        call s:EasyAlign()
    endif
endfunction

function! s:MiniAlign() " {{{1
    let alignKeystroke = luaeval('require("mini.align").config.mappings.start')
    normal! G
    let startRow = search('^([1-9]\d* rows\?\( affected\)\?)','cbW')
    while startRow > 0
        execute 'normal ' . alignKeystroke . 'ip' . b:delimiter
        let startRow = search('^([1-9]\d* rows\?\( affected\)\?)','bW')
    endwhile
endfunction

function! s:EasyAlign() " {{{1
    let threshold = sql#settings#alignLimit(sql#connection#get()[0])
    if threshold > 0
        normal! gg
        let startRow = search('^.\+$','cW')
        while startRow > 0
            let startRow += (getline(startRow) =~ '^Changed database context to' ? 1 : 0)

            let columns = count(getline(startRow), b:delimiter) + 1
            let endRow = line("'}") - (line("'}") == line("$") ? 0 : 1)
            let rows = endRow - startRow - 1
            " These coefficients were derived from an experiment I did with
            " tables as long as 10000 rows (2 columns), as wide as 2048
            " columns (10 rows), and various sizes in between.
            let timeEstimate = 0.000299808*rows*columns + 0.014503037*columns
            if timeEstimate <= threshold
                silent execute startRow . ',' . endRow . 'EasyAlign */'.b:delimiter.'/'
            endif
            normal! }
            let startRow = search('^.\+$','W')
        endwhile
    endif
endfunction
