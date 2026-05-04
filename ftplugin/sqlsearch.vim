"  vim: foldmethod=marker

nnoremap <silent> <buffer> <Esc> :call sql#search#closeWindow()<CR>
nnoremap <silent> <buffer> q :call sql#search#closeWindow()<CR>
nnoremap <silent> <buffer> h :call sql#search#closeWindow()<CR>
nnoremap <silent> <buffer> l :call sql#search#run(getline('.'))<CR>
nnoremap <silent> <buffer> <Enter> :call sql#search#run(getline('.'))<CR>
