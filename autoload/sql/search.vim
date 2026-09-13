"  vim: foldmethod=marker

function! s:generateRegex(parts)   " {{{1
    return '\c\[\?' . join(a:parts, '\]\?\.\[\?') . '\]\?'
endfunction

function! s:bufMatches(bufnr)   " {{{1
    if !buflisted(a:bufnr)
        return 0
    endif
    for p in keys(s:patterns)
        if bufname(a:bufnr) =~ printf('.*%s.*', s:patterns[p])
            return 1
        endif
    endfor
    return 0
endfunction

function! s:createPatterns()   " {{{1
    " Put the one word under the cursor into s:patterns.
    let s:patterns = {expand('<cword>'): s:generateRegex([expand('<cword>')])}

    " Parse the WORD under the cursor. Given:     '[foo.bar]."sna.fu".[baz]'
    " 1. Swap out . inside brackets or quotes:    '[foo●bar]."sna●fu".[baz]'
    " 2. Remove brackets/quotes, and split:     [ 'foo●bar', 'sna●fu', 'baz' ]
    " 3. Reintroduce brackets where needed:     [ '[foo●bar]', '[sna●fu]', 'baz' ]
    " 4. Swap the . back in:                    [ '[foo.bar]', '[sna.fu]', 'baz' ]
    let text = substitute(expand('<cWORD>'), '[["][^\]".]\+\zs\.\ze[^\]".]\+[\]"]', '●', 'g')
    let parts =  map(split(text, '\.'), {_,v -> substitute(v,'[[\]"]','','g')})
    call map(parts, {_,v -> substitute(v,'.*●.*','[&]','')})
    call map(parts, {_,v -> substitute(v,'●','.','g')})

    " schema.object are the only two-part names in the Catalog. Put any
    " pattern that may be schema.object into the dictionary.
    if len(parts) == 2          " Assume schema.object
        let s:patterns[join(parts[0:1],'.')] = s:generateRegex(parts[0:1])
    elseif len(parts) == 3      " Either schema.object.column/parameter
                                "     or database.schema.object
        let s:patterns[join(parts[0:1],'.')] = s:generateRegex(parts[0:1])
        let s:patterns[join(parts[1:2],'.')] = s:generateRegex(parts[1:2])
    elseif len(parts) == 4      " Either database.schema.object.column/parameter
                                "     or server.database.schema.object
        let s:patterns[join(parts[1:2],'.')] = s:generateRegex(parts[1:2])
        let s:patterns[join(parts[2:3],'.')] = s:generateRegex(parts[2:3])
    elseif len(parts) == 5      " Assume server.database.schema.object.column/parameter
        let s:patterns[join(parts[2:3],'.')] = s:generateRegex(parts[2:3])
    endif
endfunction

function! s:validatePatterns()   " {{{1
    let catalog = sql#catalog#getLines()
    for pattern in keys(s:patterns)
        let found = 0
        for line in catalog
            if line =~ s:patterns[pattern]
                let found = 1
                break
            endif
        endfor

        if !found
            call remove(s:patterns, pattern)
        endif
    endfor
endfunction

function! sql#search#openWindow()   " {{{1
    let s:callingBuffer = bufnr()

    call s:createPatterns()
    call s:validatePatterns()

    let buffers = sort(map(filter(range(1,bufnr('$')),{_,v -> s:bufMatches(v)}), {_,v -> '    '.bufname(v)}))

    let s:lines = flatten([
        \ 'Patterns',
        \ map(sort(keys(s:patterns)), {_,v -> '    ' . v}),
        \ '    ',
        \ 'Buffers',
        \ buffers
        \])

    let config = {
        \ 'relative': 'cursor',
        \ 'anchor': 'NW',
        \ 'row': 0,
        \ 'col': 0,
        \ 'height': len(s:lines),
        \ 'width': max( [40] + map(copy(s:lines), {_,v -> len(v)}) ),
        \ 'noautocmd': 1,
        \ 'style': 'minimal'
    \ }
    let s:searchWindow = nvim_open_win(nvim_create_buf(0,1),1,config)
    augroup SqlAuGroupSearch
        autocmd!
        autocmd BufLeave <buffer> call sql#search#closeWindow()
        autocmd CursorMoved <buffer> call sql#search#setEditability()
        autocmd TextChanged,TextChangedI <buffer> call sql#search#checkLineCount()
    augroup END

    call nvim_buf_set_lines(0, 0, -1, 0, s:lines)
    nohlsearch

    let s:ns = nvim_create_namespace('my_annotations')
    call nvim_buf_set_extmark(
        \ 0,
        \ s:ns,
        \ len(keys(s:patterns)) + 1,
        \ 0,
        \ {
        \   'virt_text': [[' ← ', 'Comment'],['o', 'Keyword'],[': other pattern', 'Comment']],
        \   'virt_text_pos': 'eol'
        \ })

    let s:backspace = &backspace
    setlocal nomodifiable filetype=sqlsearch backspace-=eol
    normal 2gg
endfunction

function! sql#search#editCustomPattern() " {{{1
    call search('\nBuffers', 'cw')
    setlocal modifiable
    execute 'normal! S    '
    startinsert!
endfunction

function! sql#search#setEditability() " {{{1
    if getline(line('.')+1) =~ '^Buffers'
        setlocal modifiable
    else
        setlocal nomodifiable
    endif

    if getline(line('.')) =~ '^\s\+'
        setlocal cursorline
    else
        setlocal nocursorline
    endif
endfunction

function! sql#search#checkLineCount() " {{{1
    if line('$') != len(s:lines)
        setlocal modifiable
        call nvim_buf_set_lines(0, 0, -1, 0, s:lines)
        setlocal nomodifiable
    endif
endfunction

function! sql#search#closeWindow() " {{{1
    if exists('s:searchWindow')
        call nvim_win_hide(s:searchWindow)
    endif
    unlet! s:searchWindow

    let &backspace = s:backspace
endfunction

function! sql#search#run(target) " {{{1
    let text = trim(getline(a:target))

    call sql#search#closeWindow()

    if text =~ '^\(Patterns\|\|Buffers\)$'
        return
    endif

    if a:target > len(keys(s:patterns)) + 3 " Matching buffer
        call sql#showSQL()
        execute 'buffer ' . escape(text, ' ')
    elseif a:target == len(keys(s:patterns)) + 2 " User-entered pattern
        let @/ = text
        call sql#catalog#show()
        normal! nzvzz
    else                        " Match in Catalog
        if &filetype == 'sql'
            " Set up the return-to SQL buffer.
            call sql#bufnr(bufnr())
        endif

        let @/ = s:patterns[text]
        call sql#catalog#show()
        normal! nzvzz
    endif
endfunction
