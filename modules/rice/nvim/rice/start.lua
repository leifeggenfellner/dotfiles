-- Start screen (D-052): the theme's title and one epigraph for the day,
-- then recent files with their real paths. Shown only when Neovim starts
-- with nothing to edit; any key that edits leaves it.
local M = {}

local function recent(limit)
  local files = {}
  for _, path in ipairs(vim.v.oldfiles) do
    if #files >= limit then
      break
    end
    if vim.fn.filereadable(path) == 1 and not path:match("^/tmp/") and not path:match("COMMIT_EDITMSG$") then
      table.insert(files, path)
    end
  end
  return files
end

local function render(opts)
  local buf = vim.api.nvim_get_current_buf()
  local width = vim.api.nvim_win_get_width(0)
  local files = recent(9)

  -- One epigraph per day, stable across editors opened that day.
  local epigraph = ""
  if #opts.epigraphs > 0 then
    epigraph = opts.epigraphs[(tonumber(os.date("%j")) % #opts.epigraphs) + 1]
  end

  local lines, marks = {}, {}
  local function add(text, group, key_len)
    table.insert(lines, text)
    if group then
      table.insert(marks, { #lines - 1, group, key_len })
    end
  end

  local body = {}
  table.insert(body, { opts.title, "RiceStartTitle" })
  table.insert(body, { "" })
  if epigraph ~= "" then
    table.insert(body, { epigraph, "RiceStartEpigraph" })
    table.insert(body, { "" })
  end
  if #files > 0 then
    table.insert(body, { opts.recentLabel, "RiceStartLabel" })
    for i, path in ipairs(files) do
      table.insert(body, { string.format("[%d]  %s", i, vim.fn.fnamemodify(path, ":~")), "RiceStartPath", 3 })
    end
    table.insert(body, { "" })
  end
  table.insert(body, { "[e] new file    [q] quit", "RiceStartLabel" })

  local column = 0
  for _, item in ipairs(body) do
    column = math.max(column, vim.fn.strdisplaywidth(item[1]))
  end
  local indent = string.rep(" ", math.max(0, math.floor((width - column) / 2)))
  local top = math.max(0, math.floor((vim.api.nvim_win_get_height(0) - #body) / 3))
  for _ = 1, top do
    add("")
  end
  for _, item in ipairs(body) do
    add(item[1] == "" and "" or indent .. item[1], item[2], item[3])
  end

  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].modified = false

  local ns = vim.api.nvim_create_namespace("rice-start")
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  for _, mark in ipairs(marks) do
    local row, group, key_len = mark[1], mark[2], mark[3]
    vim.api.nvim_buf_set_extmark(buf, ns, row, #indent, { end_col = #lines[row + 1], hl_group = group })
    if key_len then
      vim.api.nvim_buf_set_extmark(buf, ns, row, #indent, { end_col = #indent + key_len, hl_group = "RiceStartKey", priority = 200 })
    end
  end

  for i, path in ipairs(files) do
    vim.keymap.set("n", tostring(i), function()
      vim.cmd.edit(vim.fn.fnameescape(path))
    end, { buffer = buf, nowait = true })
  end
end

function M.setup(opts)
  local stdin = false
  vim.api.nvim_create_autocmd("StdinReadPre", {
    once = true,
    callback = function()
      stdin = true
    end,
  })
  vim.api.nvim_create_autocmd("VimEnter", {
    once = true,
    callback = function()
      local buf = vim.api.nvim_get_current_buf()
      if stdin or vim.fn.argc() > 0 or vim.api.nvim_buf_get_name(buf) ~= ""
          or vim.api.nvim_buf_line_count(buf) > 1 or vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] ~= "" then
        return
      end
      vim.bo[buf].buftype = "nofile"
      vim.bo[buf].bufhidden = "wipe"
      vim.bo[buf].swapfile = false
      vim.bo[buf].filetype = "rice-start"
      for option, value in pairs({ number = false, relativenumber = false, list = false, signcolumn = "no", cursorline = false }) do
        vim.api.nvim_set_option_value(option, value, { scope = "local", win = 0 })
      end
      render(opts)
      vim.keymap.set("n", "e", "<cmd>enew<cr>", { buffer = buf, nowait = true })
      vim.keymap.set("n", "q", "<cmd>qa<cr>", { buffer = buf, nowait = true })
      vim.api.nvim_create_autocmd("VimResized", { buffer = buf, callback = function() render(opts) end })
    end,
  })
end

return M
