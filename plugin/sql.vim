"  vim: foldmethod=marker

nnoremap <silent> <F8> :call sql#new()<CR>
command! SQL :call sql#new()
command! SQLUserConfig :call sql#settings#edit()

" TODO:
" - Bring back rerun capability in SQLOut
" - Get PostGres queries to work
" - Point code back to nvim-data location for usersettings.json
" - Move test usersettings.json to proper location.
" - Update README and remove superfluous comments.
" - Refactor and reduce size of code if possible.
