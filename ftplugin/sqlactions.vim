"  vim: foldmethod=marker

nnoremap <silent> <buffer> h :call sql#actions#closeWindow()<CR>
nnoremap <silent> <buffer> yl :call sql#actions#run(getline('.'), 0)<CR>
nnoremap <silent> <buffer> l :call sql#actions#run(getline('.'), 1)<CR>
