"  vim: foldmethod=marker

let g:csv_default_delim=',' " Use this to stop warning message from csv.vim plugin.

command! SQL :call sql#new()
command! SQLUserConfig :call sql#settings#edit()

call sql#settings#init(expand('<sfile>:p:h:h'))
