"  vim: foldmethod=marker

call nvim_buf_set_keymap(0, 'n', '<Esc>',   ':call sql#search#closeWindow()<CR>',       {'noremap':1, 'silent':1})
call nvim_buf_set_keymap(0, 'n', 'q',       ':call sql#search#closeWindow()<CR>',       {'noremap':1, 'silent':1})
call nvim_buf_set_keymap(0, 'n', 'h',       ':call sql#search#closeWindow()<CR>',       {'noremap':1, 'silent':1})
call nvim_buf_set_keymap(0, 'n', 'l',       ':call sql#search#run(line("."))<CR>',      {'noremap':1, 'silent':1})
call nvim_buf_set_keymap(0, 'n', '<Enter>', ':call sql#search#run(line("."))<CR>',      {'noremap':1, 'silent':1})
call nvim_buf_set_keymap(0, 'n', 'o',       ':call sql#search#editCustomPattern()<CR>', {'noremap':1, 'silent':1})
call nvim_buf_set_keymap(0, 'n', 'O',       ':call sql#search#editCustomPattern()<CR>', {'noremap':1, 'silent':1})
call nvim_buf_set_keymap(0, 'i', '<CR>',    '<ESC>:<C-U>call sql#search#run(line("."))<CR>',      {'noremap':1, 'silent':1})
