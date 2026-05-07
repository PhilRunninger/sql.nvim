"  vim: foldmethod=marker

function! s:generateRegex(parts)   " {{{1
    return '\c\[\?' . join(a:parts, '\]\?\.\[\?') . '\]\?'
endfunction

function! s:bufMatches(bufnr)   " {{{1
    if !buflisted(a:bufnr)
        return 0
    endif
    for p in keys(s:patterns)
        " if len(s:patterns[p]) == 2   " buffer must match 2-part names to reduce false positive hits
            if bufname(a:bufnr) =~ printf('.*%s.*', s:patterns[p])
                return 1
            endif
        " endif
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

    let buffers = map(filter(range(1,bufnr('$')),{_,v -> s:bufMatches(v)}), {_,v -> 'Buffer: '.bufname(v)})

    let config = {
        \ 'relative': 'cursor',
        \ 'anchor': 'NW',
        \ 'row': 0,
        \ 'col': 0,
        \ 'height': 1 + len(keys(s:patterns)) + len(buffers),
        \ 'width': max( [50] + map(keys(s:patterns) + buffers, {_,v -> len(v)}) ),
        \ 'noautocmd': 1,
        \ 'style': 'minimal',
        \ 'border': 'rounded',
        \ 'title': 'Schema.Object Search - Choose a pattern or buffer.'
    \ }
    let s:searchWindow = nvim_open_win(nvim_create_buf(0,1),1,config)
    augroup SqlAuGroup
        autocmd!
        autocmd BufLeave <buffer> call sql#search#closeWindow()
    augroup END

    setlocal modifiable filetype=sqlsearch
    call nvim_buf_set_lines(0, 0, line('$'), 1, sort(keys(s:patterns)) + ['Custom: Select to enter your own pattern.'] + sort(buffers))
    nohlsearch
    setlocal nomodifiable
endfunction

function! sql#search#closeWindow() " {{{1
    if exists('s:searchWindow')
        call nvim_win_hide(s:searchWindow)
    endif
    unlet! s:searchWindow
endfunction

function! sql#search#run(target) " {{{1
    call sql#search#closeWindow()

    if empty(a:target)
        return
    endif

    if a:target =~ '^Buffer: '
        call sql#showSQL()
        execute 'buffer ' . a:target[8:-1]
    elseif a:target =~ '^Custom: '
        let @/ = input('Enter a search pattern for the catalog: ')
        call sql#catalog#show()
        normal! nzvzz
    elseif &filetype == 'sql'
        " Set up the return-to SQL buffer.
        call sql#bufnr(bufnr())

        let @/ = s:patterns[a:target]
        call sql#catalog#show()
        normal! nzvzz
    endif
endfunction
