-- Indentation for Dart (2 spaces)
vim.opt_local.expandtab = true
vim.opt_local.tabstop = 2
vim.opt_local.shiftwidth = 2
vim.opt_local.softtabstop = 2
vim.b.autoformat = false

-- Custom Dart Smart Indentation Engine
local function dart_smart_indent()
  local ok, ts_indent = pcall(vim.fn.eval, vim.b.orig_indentexpr or "cindent(v:lnum)")
  if not ok or type(ts_indent) ~= "number" then
    ts_indent = vim.fn.cindent(vim.v.lnum)
  end

  local prev_lnum = vim.fn.prevnonblank(vim.v.lnum - 1)
  if prev_lnum == 0 then return ts_indent end

  local current_line = vim.fn.getline(vim.v.lnum)

  -- 1. Fix closing bracket indentation
  local closing_match = current_line:match("^%s*([%)%}%]])")
  if closing_match then
    local opening_map = { [")"] = "(", ["}"] = "{", ["]"] = "[" }
    local open_bracket = opening_map[closing_match]

    local saved_view = vim.fn.winsaveview()
    local col = string.find(current_line, closing_match, 1, true)
    vim.fn.cursor(vim.v.lnum, col)

    local open_lnum = vim.fn.searchpair('\\V' .. open_bracket, '', '\\V' .. closing_match, 'bW')
    local correct_indent = ts_indent
    if open_lnum > 0 then
      correct_indent = vim.fn.indent(open_lnum)
    end

    vim.fn.winrestview(saved_view)
    return correct_indent
  end

  -- 2. Safety Net: Check if previous line opened a block
  local prev_line = vim.fn.getline(prev_lnum)
  local prev_code = prev_line:gsub("//.*", ""):gsub("%s+$", "")

  if prev_code:match("[%(%{%[]$") then
    local prev_indent = vim.fn.indent(prev_lnum)
    if ts_indent <= prev_indent then
      return prev_indent + vim.fn.shiftwidth()
    end
  end

  return ts_indent
end

-- Expose to Vim's expression engine
_G.DartSmartIndent = dart_smart_indent

vim.schedule(function()
  local current_expr = vim.bo.indentexpr
  if current_expr ~= "" and not current_expr:match("DartSmartIndent") then
    vim.b.orig_indentexpr = current_expr
    vim.bo.indentexpr = "v:lua.DartSmartIndent()"
  end
end)
