-- Active rice flavour for Neovim (D-052). Theme-blind: asks rice-query for
-- the active theme and loads its generated data module
-- (rice/themes/<name>.lua). No module, no rice, or any error leaves the
-- editor exactly as configured.
local M = {}

local function active_theme()
  if vim.fn.executable("rice-query") ~= 1 then
    return nil
  end
  local out = vim.fn.system({ "rice-query", "active" })
  if vim.v.shell_error ~= 0 then
    return nil
  end
  out = vim.trim(out)
  return out:match("^[%w._-]+$") and out or nil
end

function M.apply_colors(theme)
  vim.cmd("highlight clear")
  vim.g.colors_name = "rice-" .. theme.name
  for group, spec in pairs(theme.groups) do
    vim.api.nvim_set_hl(0, group, spec)
  end
end

function M.setup()
  local name = active_theme()
  if not name then
    return
  end
  local ok, theme = pcall(require, "rice.themes." .. name)
  if not ok or type(theme) ~= "table" then
    return
  end
  if theme.groups then
    M.apply_colors(theme)
  end
  if theme.start then
    require("rice.start").setup(theme.start)
  end
end

return M
