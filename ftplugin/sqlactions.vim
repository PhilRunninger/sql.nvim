nnoremap <silent> <buffer> h :call sql#actions#closeWindow()<CR>
nnoremap <silent> <buffer> l :call sql#actions#run(getline('.'))<CR>
