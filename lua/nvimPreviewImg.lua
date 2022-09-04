local api = vim.api
local win, buf
local M = {}

function M.close_window()
  api.nvim_win_close(win, true)
end

local function open_window(scriptPath, path)

  local width = api.nvim_get_option("columns")
  local height = api.nvim_get_option("lines")

  local output = vim.fn.split(vim.fn.system("mediainfo " .. path .. " | grep -E 'Width|Height' | cut -d ':' -f2"), '\n')

  local image_width, _ = string.gsub(string.sub(output[1], 2, -7), "%s+", "") -- 8
  local image_height, _ = string.gsub(string.sub(output[2], 2, -7), "%s+", "")  -- 20

  -- window size
  local max_win_width = math.ceil(width * 0.8)
  local max_win_height = math.ceil(height * 0.8 - 4)

  local win_width, win_height
  local temp_win_height = math.ceil(image_height * max_win_width / image_width / 2)

  if temp_win_height < max_win_height then
    win_width = max_win_width
    win_height = temp_win_height
  else
    win_width = math.ceil(2.1 * image_width * max_win_height / image_height)
    win_height = max_win_height
  end

  -- window position
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

function M.PreviewImg(scriptPath, file)
  local current_win = vim.fn.win_getid()
  if current_win == win then
    M.close_window()
  else
    local path
    if file.sub(file, 1, 2) == '..' then
      path = vim.fn.expand('%:p:h') .. '/' .. file
    elseif file.sub(file, 1, 1) == '/' or file.sub(file, 1, 1) == '.' then
      path = file
    else
      api.nvim_err_writeln("It's not a right path!!!")
      return
    end
    open_window(scriptPath, path)
  end
end

return M
