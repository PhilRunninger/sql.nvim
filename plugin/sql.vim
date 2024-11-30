"  vim: foldmethod=marker

nnoremap <silent> <F8> :call sql#new()<CR>
command! SQL :call sql#new()
command! SQLUserConfig :call sql#settings#edit()
