-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
-- Remove the trailing characters by just doing :%s/\r//g
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

-- Visual-mode only: yank every other line from the visual selection into register 'a'
km({'v'}, '<leader>ya', function()
  -- get visual selection start/end (getpos returns {bufnum, lnum, col, off})
  local s_pos = vim.fn.getpos("'<")
  local e_pos = vim.fn.getpos("'>")
  local start_line = s_pos[2]
  local end_line   = e_pos[2]

  -- handle reverse selection
  if start_line > end_line then
    start_line, end_line = end_line, start_line
  end

  local lines = {}
  for i = start_line, end_line do
    -- choose every other line relative to the selection start:
    -- keep 0 -> start_line, 2 -> start_line+2, etc.
    if ((i - start_line) % 2) == 0 then
      local l = vim.api.nvim_buf_get_lines(0, i - 1, i, false)[1] or ""
      table.insert(lines, l)
    end
  end

  if #lines == 0 then
    vim.notify("No lines found to yank", vim.log.levels.INFO)
    return
  end

  -- 'l' makes the register linewise. Change 'a' to '+' to use system clipboard.
  vim.fn.setreg('a', table.concat(lines, "\n"), 'l')
end, { noremap = true, silent = true, desc = "Yank every other line from visual selection into register a" })

-- fallback detect_int_type only if you don't already define one in your config
if not detect_int_type then
  function detect_int_type()
    local line = vim.api.nvim_get_current_line()
    local t = line:match('([iu]%d+)')
    if t and t ~= "" then return t end
    local cw = vim.fn.expand('<cword>')
    t = cw:match('([iu]%d+)')
    if t and t ~= "" then return t end
    return "i64"
  end
end

local function trim(s) return (s or ""):match("^%s*(.-)%s*$") end

local function is_integer_type(t)
  if not t then return false end
  t = trim(t)
  if t:match("^[iu]%d+$") then return true end
  if t == "isize" or t == "usize" then return true end
  return false
end

local function generate_rust_getter()
  local line = vim.api.nvim_get_current_line()
  local cur = vim.api.nvim_win_get_cursor(0) -- {row, col}
  local row = cur[1] - 1 -- 0-indexed for buffer ops

  -- parse "name: type," allowing underscores and whitespace
  local name, raw_type = line:match("^%s*([%w_]+)%s*:%s*(.-)%s*,?%s*$")
  if not name or not raw_type or raw_type == "" then
    vim.notify("Could not parse a field declaration on this line.", vim.log.levels.WARN)
    return
  end
  raw_type = trim(raw_type)

  -- detect Option<Inner> or plain type
  local inner = raw_type:match("^Option%s*<%s*(.-)%s*>$")
  local is_option = inner ~= nil
  if is_option then inner = trim(inner) end

  if is_option and (inner == "" or not inner) then
    inner = detect_int_type()
  end
  if not is_option and (raw_type == "" or not raw_type) then
    raw_type = detect_int_type()
  end

  local indent = line:match("^(%s*)") or ""
  local fn_indent = indent .. "    "

  local fn_name = "get_" .. name
  local ret_type, body_line

  if is_option then
    if is_integer_type(inner) then
      ret_type = "Option<" .. inner .. ">"
      body_line = "self." .. name
    elseif inner == "String" then
      ret_type = "Option<&String>"
      body_line = "self." .. name .. ".as_ref()"
    else
      ret_type = "Option<&" .. inner .. ">"
      body_line = "self." .. name .. ".as_ref()"
    end
  else
    local t = raw_type
    if is_integer_type(t) then
      ret_type = t
      body_line = "self." .. name
    elseif t == "String" then
      ret_type = "&String"
      body_line = "&self." .. name
    else
      ret_type = "&" .. t
      body_line = "&self." .. name
    end
  end

  -- assemble function (replace the original field line with these lines)
  local lines = {
    indent .. "pub fn " .. fn_name .. "(&self) -> " .. ret_type .. " {",
    fn_indent .. body_line,
    indent .. "}"
  }

  -- replace current line (row .. row+1) with function lines
  vim.api.nvim_buf_set_lines(0, row, row + 1, false, lines)

  -- compute target row (line immediately after final '}'), 0-indexed
  local target_row = row + #lines

  -- ensure there is at least one line after the inserted function; if not, append a blank line
  local line_count = vim.api.nvim_buf_line_count(0)
  if target_row >= line_count then
    vim.api.nvim_buf_set_lines(0, line_count, line_count, false, {""})
    line_count = vim.api.nvim_buf_line_count(0)
  end

  -- put the cursor at the first column of the line after the function
  vim.api.nvim_win_set_cursor(0, { target_row + 1, 0 })

  vim.notify("Replaced field with getter '" .. fn_name .. "' -> " .. ret_type, vim.log.levels.INFO)
end

-- mapping (normal mode): <leader>rg to generate getter from current line
km({'n'}, '<leader>rg', function() generate_rust_getter() end,
  { noremap = true, silent = true, desc = "Generate Rust getter from field declaration (replace line)" })
