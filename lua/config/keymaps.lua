-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
--
--

local km = vim.keymap.set

local function sanitize_ident(s)
  if not s then return "" end
  return (s:gsub('[^%w_]', '')):gsub('^%d+', '')  -- remove non-word, and leading digits if any
end

-- parse field name from the current line: matches "    name: Type" style
local function field_from_current_line()
  local line = vim.api.nvim_get_current_line()
  -- try to capture `name` from "name: Type" allowing whitespace
  local field = line:match('^%s*([%w_]+)%s*:')
  if field and field ~= "" then
    return field
  end
  -- fallback to word under cursor
  local cw = vim.fn.expand('<cword>')
  return sanitize_ident(cw)
end


local function detect_int_type()
  local line = vim.api.nvim_get_current_line()
  -- find first integer type like i8, i16, i32, i64, i128 (flexible)
  local t = line:match('i%d+')
  if t and t ~= "" then return t end
  -- fallback: check word under cursor
  local cw = vim.fn.expand('<cword>')
  t = cw:match('i%d+')
  if t and t ~= "" then return t end
  -- default
  return "i64"
end


local function insert_getter_replacing_line(return_type, body_expr_fmt)
  local buf = 0
  local row = vim.api.nvim_win_get_cursor(0)[1]  -- 1-indexed
  local curline = vim.api.nvim_get_current_line()
  local indent = curline:match('^%s*') or ''

  local raw_field = field_from_current_line()
  local field = sanitize_ident(raw_field)
  if field == "" then
    vim.notify("No valid identifier on current line", vim.log.levels.WARN)
    return
  end

  local fn_name = "get_" .. field
  local body = string.format(body_expr_fmt, field)

  local lines = {
    indent .. string.format("pub fn %s(&self) -> %s {", fn_name, return_type),
    indent .. "    " .. body,
    indent .. "}",
  }

  -- replace the current line with the function
  vim.api.nvim_buf_set_lines(buf, row - 1, row, true, lines)

  -- target_row is where the original next line will now be
  local target_row = row + #lines

  -- ensure target_row exists; if not, append an empty line
  local nlines = vim.api.nvim_buf_line_count(buf)
  if target_row > nlines then
    vim.api.nvim_buf_set_lines(buf, -1, -1, true, {""})
    nlines = nlines + 1
  end

  -- place cursor on that next/or appended line, column 0
  vim.api.nvim_win_set_cursor(0, { math.min(target_row, nlines), 0 })
end

local function insert_setter_replacing_line(param_type, assign_fmt)
  local buf = 0
  local row = vim.api.nvim_win_get_cursor(0)[1]  -- 1-indexed
  local curline = vim.api.nvim_get_current_line()
  local indent = curline:match('^%s*') or ''

  local raw_field = field_from_current_line()
  local field = sanitize_ident(raw_field)
  if field == "" then
    vim.notify("No valid identifier on current line", vim.log.levels.WARN)
    return
  end

  local fn_name = "set_" .. field

  local lines = {
    indent .. string.format("pub fn %s(&mut self, value: %s) -> &mut Self {", fn_name, param_type),
    indent .. "    " .. string.format(assign_fmt, field),
    indent .. "    self",
    indent .. "}",
  }

  vim.api.nvim_buf_set_lines(buf, row - 1, row, true, lines)

  local target_row = row + #lines
  local nlines = vim.api.nvim_buf_line_count(buf)
  if target_row > nlines then
    vim.api.nvim_buf_set_lines(buf, -1, -1, true, {""})
    nlines = nlines + 1
  end

  vim.api.nvim_win_set_cursor(0, { math.min(target_row, nlines), 0 })
end


local function insert_int_getter_from_line()
  local ty = detect_int_type()
  insert_getter_replacing_line(ty, "self.%s")
end

local function insert_int_setter_from_line()
  local ty = detect_int_type()
  insert_setter_replacing_line(ty, "self.%s = value;")
end

-- Mappings: leader+fs -> &str getter, leader+fi -> i64 getter
km('n', '<leader>fgs', function() insert_getter_replacing_line("&str", "&self.%s") end, { noremap = false, silent = true, desc = "get &str" })
km('n', '<leader>fgi', insert_int_getter_from_line, { noremap = false, silent = true, desc = "get integer/same format" })
km('n', '<leader>fss', function() insert_setter_replacing_line("&str", "self.%s = value.to_string();") end, { noremap = false, silent = true, desc = "insert &str"})
km('n', '<leader>fsi', insert_int_setter_from_line, { noremap = false, silent = true, desc = "insert integer/same format"})


-- Macros Example down below
-- km('n', '<leader>fvs', '<cmd>norm ^yiwo<esc>p<CR>', { noremap = true, silent = true})
km(
  'n',
  '<leader>fvs', 
  '0w"ayiwipub<space>fn<space>insert_<Esc>f:i(&mut self, <Esc>"apa: &str)<Esc>f:<S-C> -> &mut Self {<Esc>oself.<Esc>"apa.push(<Esc>"apa.to_string());<Esc>oself<Esc>o}<Esc>j',
  { noremap = true, silent = true}
)

km(
  'n',
  '<leader>fvi',
  '0w"ayiwipub<space>fn<space>insert_<Esc>f:i(&mut self, <Esc>"apa<Esc>f<w"byiwF:lD"bpa) -> &mut Self {<Esc>oself.<Esc>"apa.push(<Esc>"apa);<Esc>oself<Esc>o}<Esc>j',
  {noremap = true, silent = true}
)

km(
	'n',
	'<leader>fo',
	'0f:wvt,cOption<<Esc>pa><Esc>j',
	{ noremap = true, silent = true}
)


km('n', '<leader>vv', function ()
	require('telescope.builtin').lsp_document_symbols({
		symbols = {"Variable", "Constant", "Field"}
	})
end, {desc = "Document Variables"})


km('n', '<leader>ya', function()
  local lines = {}
  local last = vim.api.nvim_buf_line_count(0)
  for i = 1, last do
    if i % 2 == 0 then
      local l = vim.api.nvim_buf_get_lines(0, i-1, i, false)[1] or ""
      table.insert(lines, l)
    end
  end

  if #lines == 0 then
    vim.notify("No lines found to yank", vim.log.levels.INFO)
    return
  end

  -- Use linewise register so pastes keep line boundaries. Use 'a' or change to '+' for system clipboard.
  vim.fn.setreg('a', table.concat(lines, "\n"), 'l')
end, { noremap = true, silent = true, desc = "Yank every other (even) line into register a" })


