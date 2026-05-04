"  vim: foldmethod=marker

nnoremap <silent> <buffer> <Esc> :call sql#actions#closeWindow()<CR>
nnoremap <silent> <buffer> q :call sql#actions#closeWindow()<CR>
nnoremap <silent> <buffer> h :call sql#actions#closeWindow()<CR>
nnoremap <silent> <buffer> yl :call sql#actions#run(getline('.'), 0)<CR>
nnoremap <silent> <buffer> l :call sql#actions#run(getline('.'), 1)<CR>
nnoremap <silent> <buffer> <Enter> :call sql#actions#run(getline('.'), 1)<CR>
