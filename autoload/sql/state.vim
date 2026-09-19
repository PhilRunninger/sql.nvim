"  vim: foldmethod=marker

let s:stateFilePath = stdpath('data') . '\sql.nvim\userstate.json'

function! sql#state#read() abort   "{{{1
    if exists('s:state')
        return s:state
    endif

    if !filereadable(s:stateFilePath)
        let s:state = {"version":3, "connections":{}, "marks":{}}
        return s:state
    endif

    " Migrate the user state file to the lastest version. Store in script variable.

    " Version 1: [{"file": path, "plt": platform, "srv": server, "db": database, "accessed": 1234567890},...]
    let s:state = json_decode(readfile(s:stateFilePath))

    if type(s:state) == v:t_list

        " Version 2: [{"file": path, "plt": platform, "srv": server, "db": database, "date": "2026-05-08T23:26:53"},...]
        " Convert v1 Unix timestamp to v2 ISO date string, and rename `accessed` to `date`.
        for conn in s:state
            if has_key(conn, 'accessed')
                let conn['date'] = conn.accessed
                call remove(conn, 'accessed')
            endif

            if type(conn.date) == v:t_number
                let conn.date = strftime('%Y-%m-%dT%H:%M:%S', conn.date)
            endif
        endfor

        " Version 3:
        "   {
        "       "version":3,
        "       "connections":{file1:{"db":[platform, server, database], "date":date},...},
        "       "marks":{mark1:[platform, server, database],...}
        "   }
        let temp = {}
        for conn in s:state
            let temp[conn.file] = {'db': [conn.plt, conn.srv, conn.db], 'date': conn.date}
        endfor
        let s:state = { 'version': 3, 'connections': temp, 'marks': {} }
    endif

    return s:state
endfunction

function! sql#state#getConnection(bufnr) abort   " {{{1
    let filename = fnamemodify(bufname(str2nr(a:bufnr)), ':p')

    if has_key(s:state.connections, filename)
        return s:state.connections[filename].db
    endif

    return []
endfunction

function! sql#state#saveAs(abuf, afile) abort   " {{{1
    " This function is specifically designed to handle saving a
    " &buftype=nofile buffer when using the `:w filename` command. That's the
    " only way to save such a buffer. It just so happens to work when saving
    " normal SQL buffers too. <abuf> refers to the original buffer, and
    " <afile> is the new filename.
    let filename = fnamemodify(a:afile, ':p')
    let conn = sql#state#getConnection(a:abuf)
    if !empty(conn)
        let s:state.connections[filename] = {'db': conn, 'date':strftime('%Y-%m-%dT%H:%M:%S')}
    endif
endfunction

function! sql#state#setConnection(bufnr, db) abort   " {{{1
    let filename = fnamemodify(bufname(str2nr(a:bufnr)), ':p')
    let s:state.connections[filename] = {'db': a:db, 'date':strftime('%Y-%m-%dT%H:%M:%S')}
endfunction

function! sql#state#getMarks() abort   " {{{1
    return s:state.marks
endfunction

function! sql#state#deleteMark(mark) abort   " {{{1
    if has_key(s:state.marks, a:mark)
        call remove(s:state.marks, a:mark)
    endif
endfunction

function! sql#state#saveMark(mark, db) abort   " {{{1
    let s:state.marks[a:mark] = a:db
endfunction

function! sql#state#write() abort   " {{{1
    for bufnr in range(1,bufnr('$'))
        if !buflisted(bufnr)
            continue
        endif

        let filename = fnamemodify(bufname(bufnr), ':p')

        " Don't save connections for nofile buffers.
        if getbufvar(bufnr, '&buftype') == 'nofile'
            call remove(s:state.connections, filename)
        endif

        " Update the access date for all connections to open buffers.
        if has_key(s:state.connections, filename)
            let s:state.connections[filename].date = strftime('%Y-%m-%dT%H:%M:%S')
        endif
    endfor

    " Limit the number of saved connections to 500. Remove the oldest if we exceed that.
    let sortedConnections = sort(items(s:state.connections), {a,b -> a[1].date < b[1].date ? 1 : -1})
    if len(sortedConnections) > 500
        for oldConnection in remove(sortedConnections, 500, -1)
            call remove(s:state.connections, oldConnection[0])
        endfor
    endif

    call writefile([json_encode(s:state)], s:stateFilePath)
endfunction

