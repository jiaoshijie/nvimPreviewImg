local scriptPath = vim.fn.expand('<sfile>:p:h') .. '/../showImg'

vim.api.nvim_create_user_command("ShowImg", function(opts) require('nvimPreviewImg').PreviewImg(scriptPath, opts.args) end, { nargs = 1, complete = "file" })
vim.keymap.set("n", "<leader>p", ":ShowImg <cfile><cr>", { noremap = true, silent = true })
