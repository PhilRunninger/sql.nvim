" vim: foldmethod=marker
"
" Key mappings and settings for the SQLCatalog buffer. {{{1

nnoremap <silent> <buffer> <Esc> :call <SID>CloseMe()<CR>
nnoremap <silent> <buffer> q :call <SID>CloseMe()<CR>
nnoremap <silent> <buffer> h :call <SID>Collapse()<CR>
nnoremap <silent> <buffer> l :call <SID>ExpandOrOpenMenu()<CR>
nnoremap <silent> <buffer> <Enter> :call <SID>SetConnection()<CR>
nnoremap <silent> <buffer> <F5> :call <SID>Refresh()<CR>
nnoremap <silent> <buffer> <F8> :call sql#showSQL()<CR>
nnoremap <silent> <buffer> J ]z
nnoremap <silent> <buffer> K [z
nnoremap <silent> <buffer> <C-F3> :call sql#search#start()<CR>
nnoremap <silent> <buffer> <F3> :call sql#search#next()<CR>
nnoremap <silent> <buffer> <S-F3> :call sql#search#next(-1)<CR>

setlocal nomodifiable
setlocal bufhidden=hide buftype=nofile noswapfile
setlocal cursorline
setlocal nowrap nonumber norelativenumber nolist winfixwidth winfixbuf
setlocal signcolumn=no
setlocal foldopen-=search
setlocal conceallevel=3 concealcursor=nvic
setlocal fillchars=fold:\ ,eob:\  foldcolumn=0 foldmethod=expr foldexpr=SQLCatalogFoldLevel(v:lnum)
setlocal foldtext=getline(v:foldstart)

function! SQLCatalogFoldLevel(lnum) " {{{1
    let l:current_indent = 1 + len(matchstr(getline(a:lnum),'^ *')) / 2
    let l:next_indent = 1 + len(matchstr(getline(a:lnum + 1),'^ *')) / 2

    if l:current_indent < l:next_indent
        return '>' . l:current_indent
    elseif l:current_indent > l:next_indent
        return '<' . (l:current_indent - 1)
    else
        return l:current_indent - 1
    endif
endfunction

function! s:Collapse() " {{{1
    if foldlevel('.') > 0
        normal zc0
    endif
    if foldclosed('.') != -1
        call cursor(foldclosed('.'), 1)
    endif
endfunction

function! s:ExpandOrOpenMenu() " {{{1
    if foldclosed('.') != -1
        normal! zo0
    endif

    let current = s:ObjectUnderCursor()
    let delimiter = sql#settings#delimiter(current.platform.text)
    if current.cursor.text =~ printf('^%s', g:sql#unexplored)    " Unexplored server
        let masterDB = sql#settings#app()[current.platform.text].actions.Catalog.masterDB
        call sql#query#run(function('s:GetDBInfoCallback', [current.cursor.line, printf('  %s ', g:sql#unexplored)]), delimiter, current.platform.text, current.server.text, masterDB, 'Catalog', 'GetDatabases')
    elseif current.cursor.text =~ printf('^  %s', g:sql#unexplored)    " Unexplored database
        call sql#query#run(function('s:GetDBInfoCallback', [current.cursor.line, '    ']), delimiter, current.platform.text, current.server.text, current.database.text, 'Catalog', 'GetDatabaseObjects')
    elseif current.cursor.text =~ '^      \(  \)\?'   " DB Object or Type
        call sql#actions#openWindow(current.platform.text, current.server.text, current.database.text, current.type.text, current.object.text)
    endif
endfunction

function! s:Refresh() " {{{1
    setlocal modifiable
    let current = s:ObjectUnderCursor()
    if current.cursor.text =~ printf('^[%s%s]', g:sql#unexplored, g:sql#explored)    " Cursor is on a server. Remove all databases, and set server to be unexplored.
        call cursor(current.server.line, 1)
        normal! ]z
        let lastLine = line('.')
        call nvim_buf_set_lines(0,current.server.line-1,lastLine,0,[printf('%s %s (%s)', g:sql#unexplored, current.server.text, current.platform.text)])
        call cursor(current.server.line, 1)
    else    " Cursor is on a database. Remove all of its objects, and set database to unexplored.
        call cursor(current.database.line, 1)
        normal! ]z
        let lastLine = line('.')
        call nvim_buf_set_lines(0,current.database.line-1,lastLine,0,[printf('  %s %s', g:sql#unexplored, current.database.text)])
        call cursor(current.database.line, 1)
    endif
    setlocal nomodifiable
    call s:ExpandOrOpenMenu()   " Allow the Expand functionality to repopulate the removed items.
endfunction

function! s:GetDBInfoCallback(line, prefix, job_id, data, event) " {{{1
    stopinsert
    call sql#showCatalog()

    let data = filter(copy(a:data), {_,v -> !empty(v)})
    if empty(data) | return | endif

    setlocal modifiable
    call nvim_buf_set_lines(0,a:line-1,a:line,0,[substitute(getline(a:line), g:sql#unexplored, g:sql#explored, '')])
    call nvim_buf_set_lines(0,a:line,a:line,0,map(data, {_,v -> a:prefix.substitute(v, nr2char(13).'$','','')}))
    setlocal nomodifiable

    call s:SetMarks()

    call cursor(a:line,1)
    normal! zmzv0
endfunction

function! s:SetMarks()   " {{{1
    let userSettings = sql#settings#user()
    for platform in keys(userSettings)
        for server in keys(userSettings[platform].servers)
            let marks = sql#settings#marks(platform, server)
            for mark in keys(marks)
                normal! gg
                while search('^  \S ' . marks[mark], 'W') > 0
                    let current = s:ObjectUnderCursor()
                    if current.platform.text != platform | continue | endif
                    if current.server.text != server | continue | endif

                    call nvim_buf_del_mark(0, mark)
                    call nvim_buf_set_mark(0, mark, line('.'), 1, {})

                    let ns = nvim_create_namespace('sqlCatalogMarks')
                    let id = char2nr(mark)
                    call nvim_buf_del_extmark(0, ns, id)
                    call nvim_buf_set_extmark(0, ns, line('.')-1,0, {'id':id, 'virt_text':[[mark,'SqlCatalogMark']], 'virt_text_pos':'overlay'})
                endwhile
            endfor
        endfor
    endfor
endfunction

function! s:CloseMe() " {{{1
    let winnr = winnr()
    execute bufwinnr(sql#bufnr()).'wincmd w'
    execute winnr.'wincmd c'
endfunction

function! s:SetConnection() " {{{1
    if getline('.') !~ '^  '
        echo 'Your cursor must be within a database to choose a connection.'
        return
    endif

    let current = s:ObjectUnderCursor()
    call sql#connection#set(current.platform.text, current.server.text, current.database.text)
endfunction

function! s:ObjectUnderCursor() " {{{1
    let server   = search('^\S','bcnW')
    let database = search('^  \S', 'bcnW')
    let type     = search('^    \S','bcnW')
    let object   = search('^      \S','bcnW')

    if database < server
        let [database, type, object] = [0, 0, 0]
    endif
    if type < database
        let [type, object] = [0, 0]
    endif
    if object < type
        let object = 0
    endif

    try
        return #{
            \ cursor:   #{line: line('.'), text: getline('.')},
            \ server:   #{line: server,    text: matchlist(getline(server), '^..\(.*\) (\(.*\))$')[1]},
            \ platform: #{line: server,    text: matchlist(getline(server), '^..\(.*\) (\(.*\))$')[2]},
            \ database: #{line: database,  text: matchstr(getline(database), '^  ..\zs.*\ze$')},
            \ type:     #{line: type,      text: trim(getline(type))},
            \ object:   #{line: object,    text: trim(getline(object))}
            \ }
    catch
        return #{
            \ cursor:   #{line: line('.'), text: getline('.')},
            \ server:   #{line: 0,         text: ''},
            \ platform: #{line: 0,         text: ''},
            \ database: #{line: 0,         text: ''},
            \ type:     #{line: 0,         text: ''},
            \ object:   #{line: 0,         text: ''}
            \ }
    endtry
endfunction

function SqlCatalogStatusLine() " {{{1
    let current = s:ObjectUnderCursor()
    let text = current.server.text
    if current.database.text != ''
        let text .= '.' . current.database.text
    endif
    if current.type.text != ''
        let text .= ' ' . tolower(current.type.text)
    endif

    return text
endfunction

setlocal statusline=%{SqlCatalogStatusLine()}
