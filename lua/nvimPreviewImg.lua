local api = vim.api
local win, buf
local M = {}

local scriptPath = vim.fn.expand('<sfile>:p:h') .. '/../showImg'

function M.close_window()
  api.nvim_win_close(win, true)
end

local function open_window(path)

  -- window size
  local width = api.nvim_get_option("columns")
  local height = api.nvim_get_option("lines")
  local win_height = math.ceil(height * 0.8 - 4)
  local win_width = math.ceil(width * 0.8)
  local row = math.ceil((height - win_height) / 2 - 1)
  local col = math.ceil((width - win_width) / 2)

  -- BORDERS
  local border_buf = api.nvim_create_buf(false, true)
  local title = 'PreviewImg'
  local border_opts = {
    style = "minimal",
    relative = "editor",
    width = win_width + 2,
    height = win_height + 2,
    row = row - 1,
    col = col - 1,
  }
  local border_lines = {
    '┌' .. title .. string.rep('─', win_width - #title) .. '┐',
  }
  local middle_line = '│' .. string.rep(' ', win_width) .. '│'
  for _ = 1, win_height do
    table.insert(border_lines, middle_line)
  end
  table.insert(border_lines, '└' .. string.rep('─', win_width) .. '┘')
  api.nvim_buf_set_lines(border_buf, 0, -1, false, border_lines)
  api.nvim_open_win(border_buf, true, border_opts)

  local opts = {
    style = "minimal",
    relative = "editor",
    width = win_width,
    height = win_height,
    row = row,
    col = col,
  }

  -- create preview buffer and set local options
  buf = api.nvim_create_buf(false, true)
  win = api.nvim_open_win(buf, true, opts)
  api.nvim_command("au BufWipeout <buffer> exe 'silent bwipeout! '" .. border_buf)
  api.nvim_buf_set_keymap(buf, "n", "q", ":lua require('nvimPreviewImg').close_window()<cr>",
                          {noremap = true, silent = true})
  api.nvim_buf_set_keymap(buf, "n", "<Esc>", ":lua require('nvimPreviewImg').close_window()<cr>",
                          {noremap = true, silent = true})

  -- set local options
  api.nvim_buf_set_option(buf, "bufhidden", "wipe")
  api.nvim_win_set_option(win, "winblend", 0)
  vim.fn.termopen(string.format("%s %s %s %s %s %s", scriptPath, col, row,
                                win_width, win_height,
                                vim.fn.shellescape(path)))
end

function M.PreviewImg(file)
  local current_win = vim.fn.win_getid()
  if current_win == win then
    M.close_window()
  else
    if file.sub(file, 1, 2) == '..' then
      open_window(vim.fn.expand('%:p:h') .. '/' .. file)
    elseif file.sub(file, 1, 1) == '/' then
      open_window(file)
    elseif file.sub(file, 1, 1) == '.' then
      open_window(file)
    else
      api.nvim_err_writeln("It's not a right path!!!")
    end
  end
end

function M.create_commands()
  api.nvim_exec([[
    command! -nargs=? -complete=file ShowImg :lua require('nvimPreviewImg').PreviewImg(<q-args>)
    nnoremap <silent> <leader>P :ShowImg <cfile><cr>
  ]], false)
end

return M
