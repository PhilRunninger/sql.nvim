"  vim: foldmethod=marker

" Retreive and save state per file - saved connection info.   {{{1
let s:stateFilePath = stdpath('data') . '\sql.nvim\userstate.json'

function! sql#state#getConnection() abort   " {{{2
    let allConnections = s:migrate()

    call sort(allConnections, {a, b -> 2*(b.date > a.date) - 1})

    let connection = filter(copy(allConnections), {_,v -> v.file == fnamemodify(bufname(bufnr()),':p')})
    if !empty(connection)
        call sql#connection#set(connection[0].plt, connection[0].srv, connection[0].db)
    endif

    return allConnections
endfunction

function! sql#state#saveConnections(bufnr) abort   " {{{2
    echo 'saving'
    if getbufvar(a:bufnr, '&buftype') == 'nofile'
        return
    endif

    echomsg 'not nofile'

    let state = sql#connection#get(a:bufnr)
    if empty(state)
        return
    endif

    echomsg a:bufnr
    echomsg bufname(a:bufnr)
    echomsg fnamemodify(bufname(a:bufnr),':p')

    let allConnections = sql#state#getConnection()
    let newConnection = {'date':strftime('%Y-%m-%dT%H:%M:%S'), 'file':fnamemodify(bufname(a:bufnr),':p'), 'plt':state[0], 'srv':state[1], 'db':state[2]}

    let idx = -1
    for i in range(len(allConnections))
        if allConnections[i].file == fnamemodify(bufname(a:bufnr),':p')
            let idx = i
            break
        endif
    endfor

    if idx > -1
        call remove(allConnections, idx)
    endif
    call insert(allConnections, newConnection)

    if len(allConnections) > 500
        call remove(allConnections, 500, -1)
    endif

    call writefile([json_encode(allConnections)], s:stateFilePath)
endfunction

function! s:migrate() abort   " {{{2
    if !filereadable(s:stateFilePath)
        return []
        " return {"version": 3, "connections": [], "marks":{}}
    endif

    " Version 1: [{"file": path, "plt": platform, "srv": server, "db": database, "accessed": 1234567890},...]
    let state = json_decode(readfile(s:stateFilePath))

    if type(state) == v:t_list

        " Version 2: [{"file": path, "plt": platform, "srv": server, "db": database, "date": "2026-05-08T23:26:53"},...]
        " Convert v1 Unix timestamp to v2 ISO date string, and rename `accessed` to `date`.
        for connection in state
            if has_key(connection, 'accessed')
                let connection['date'] = connection.accessed
                call remove(connection, 'accessed')
            endif

            if type(connection.date) == v:t_number
                let connection.date = strftime('%Y-%m-%dT%H:%M:%S', connection.date)
            endif
        endfor

    endif

    return state
endfunction
