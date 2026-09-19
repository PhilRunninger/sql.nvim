"  vim: foldmethod=marker

call nvim_buf_set_keymap(0, 'n', 'h',       ':call sql#actions#closeWindow()<CR>',       {'noremap':1, 'silent':1})
call nvim_buf_set_keymap(0, 'n', 'yl',      ':call sql#actions#run(getline("."),0)<CR>', {'noremap':1, 'silent':1})
call nvim_buf_set_keymap(0, 'n', 'l',       ':call sql#actions#run(getline("."),1)<CR>', {'noremap':1, 'silent':1})
