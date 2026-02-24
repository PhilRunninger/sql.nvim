"  vim: foldmethod=marker

let s:bufferName = '⟪SQLOut⟫'

function! s:dividingLine() " {{{1
    return '^-\+\(' . b:delimiter . '-\+\)*$'
endfunction

function! sql#sqlout#open(enter) " {{{1
    let bufnr = bufnr(s:bufferName)
    if bufnr == -1
        let bufnr = bufnr(s:bufferName, 1)
        call nvim_set_option_value('buftype',  'nofile', {'buf':bufnr})
        call nvim_set_option_value('filetype', 'csv',    {'buf':bufnr})
        call nvim_set_option_value('swapfile', v:false,  {'buf':bufnr})

        call nvim_buf_set_keymap(bufnr, 'n', '<F3>',   ':call sql#search#start(expand("<cword>"))<CR>', {'silent':1})
        call nvim_buf_set_keymap(bufnr, 'n', '<C-F3>', ':call sql#search#start("")<CR>', {'silent':1})
        call nvim_buf_set_keymap(bufnr, 'n', '<F5>', ' :call RunQuery(b:delimiter)<CR>', {'noremap':1, 'silent':1})
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

function! sql#sqlout#toMarkdown()
    if bufname(bufnr()) !=# s:bufferName
        echohl WarningMsg
        echo 'This command must be run in the ' . s:bufferName . ' buffer.'
        return
    endif

    silent execute 'keeppatterns g/' . s:dividingLine() . '/s/-\+/---/g'
    silent execute 'keeppatterns %s/ *' . b:delimiter . ' */|/g'
endfunction

function! sql#sqlout#format() " {{{1
    " Add newline before each column header row, but not line 1.
    if line('$') > 1
        execute '2,$s/.*\n' . s:dividingLine() . '/\r&/e'

        call s:JoinLines()
        call s:AlignColumns()
        normal! gg
    endif

    syntax clear
    source $VIMRUNTIME/**/syntax/csv.vim
endfunction

function! s:JoinLines() " {{{1
    normal! gg
    let startRow = search(s:dividingLine(),'cW') - 1
    while startRow > -1
        call cursor(startRow,1)
        let endRow = search('^$', 'cW') - 1
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
        call cursor(endRow+1,1)
        let startRow = search(s:dividingLine(),'cW') - 1
    endwhile
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
    while search(s:dividingLine(),'bW') > 0
        execute 'normal ' . alignKeystroke . 'ip' . b:delimiter
    endwhile
endfunction

function! s:EasyAlign() " {{{1
    let timeLimit = sql#settings#alignLimit(sql#connection#get()[0])
    if timeLimit > 0
        normal! G
        while search(s:dividingLine(),'bW') > 0
            let columns = count(getline('.'), b:delimiter) + 1
            let rows = line("'}") - line("'{") - 1
            if 0.0003*rows*columns + 0.015*columns <= timeLimit
                silent execute "'{,'}EasyAlign */" . b:delimiter . '/'
            endif
            normal! {
        endwhile
    endif
endfunction
