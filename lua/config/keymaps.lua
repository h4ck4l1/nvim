local km = vim.keymap.set

local function sanitize_ident(s)
  if not s then
    return ""
  end
  return (s:gsub("[^%w_]", "")):gsub("^%d+", "") -- remove non-word, and leading digits if any
end

-- parse field name from the current line: matches "    name: Type" style
local function field_from_current_line()
  local line = vim.api.nvim_get_current_line()
  -- try to capture `name` from "name: Type" allowing whitespace
  local field = line:match("^%s*([%w_]+)%s*:")
  if field and field ~= "" then
    return field
  end
  -- fallback to word under cursor
  local cw = vim.fn.expand("<cword>")
  return sanitize_ident(cw)
end

local function detect_int_type()
  local line = vim.api.nvim_get_current_line()
  -- find first integer type like i8, i16, i32, i64, i128 (flexible)
  local t = line:match("[iu]%d+")
  if t and t ~= "" then
    return t
  end
  -- fallback: check word under cursor
  local cw = vim.fn.expand("<cword>")
  t = cw:match("[iu]%d+")
  if t and t ~= "" then
    return t
  end
  -- default
  return "i64"
end

local function insert_getter_replacing_line(return_type, body_expr_fmt)
  local buf = 0
  local row = vim.api.nvim_win_get_cursor(0)[1] -- 1-indexed
  local curline = vim.api.nvim_get_current_line()
  local indent = curline:match("^%s*") or ""

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
    vim.api.nvim_buf_set_lines(buf, -1, -1, true, { "" })
    nlines = nlines + 1
  end

  -- place cursor on that next/or appended line, column 0
  vim.api.nvim_win_set_cursor(0, { math.min(target_row, nlines), 0 })
end

local function insert_setter_replacing_line(param_type, assign_fmt)
  local buf = 0
  local row = vim.api.nvim_win_get_cursor(0)[1] -- 1-indexed
  local curline = vim.api.nvim_get_current_line()
  local indent = curline:match("^%s*") or ""

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
    vim.api.nvim_buf_set_lines(buf, -1, -1, true, { "" })
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
km("n", "<leader>fgs", function()
  insert_getter_replacing_line("&str", "&self.%s")
end, { noremap = false, silent = true, desc = "get &str" })
km(
  "n",
  "<leader>fgi",
  insert_int_getter_from_line,
  { noremap = false, silent = true, desc = "get integer/same format" }
)
km("n", "<leader>fss", function()
  insert_setter_replacing_line("&str", "self.%s = value.to_string();")
end, { noremap = false, silent = true, desc = "insert &str" })
km(
  "n",
  "<leader>fsi",
  insert_int_setter_from_line,
  { noremap = false, silent = true, desc = "insert integer/same format" }
)

-- Macros Example down below
-- km('n', '<leader>fvs', '<cmd>norm ^yiwo<esc>p<CR>', { noremap = true, silent = true})
km(
  "n",
  "<leader>fvs",
  '0w"ayiwipub<space>fn<space>insert_<Esc>f:i(&mut self, <Esc>"apa: &str)<Esc>f:<S-C> -> &mut Self {<Esc>oself.<Esc>"apa.push(<Esc>"apa.to_string());<Esc>oself<Esc>o}<Esc>j',
  { noremap = true, silent = true }
)

km(
  "n",
  "<leader>fvi",
  '0w"ayiwipub<space>fn<space>insert_<Esc>f:i(&mut self, <Esc>"apa<Esc>f<w"byiwF:lD"bpa) -> &mut Self {<Esc>oself.<Esc>"apa.push(<Esc>"apa);<Esc>oself<Esc>o}<Esc>j',
  { noremap = true, silent = true }
)

km("n", "<leader>fo", "0f:wvt,cOption<<Esc>pa><Esc>j", { noremap = true, silent = true })

km("n", "<leader>vv", function()
  require("telescope.builtin").lsp_document_symbols({
    symbols = { "Variable", "Constant", "Field" },
  })
end, { desc = "Document Variables" })

vim.keymap.set("v", "<leader>ya", function()
  -- 1. Capture coordinates immediately
  local s_line = vim.fn.line("v")
  local e_line = vim.fn.line(".")
  local start_col = vim.fn.col("v")

  -- 2. Exit visual mode to prevent crashes/UI collisions
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "x", false)

  vim.schedule(function()
    -- Interactive inputs
    local n_str = vim.fn.input("Yank every n-th line: ", "2")
    local n = tonumber(n_str) or 1
    if n < 1 then
      n = 1
    end

    local delim = vim.fn.input("Delimiter (Empty for whole line): ")

    -- IMPROVEMENT: Default to '+' (System Clipboard) for cross-terminal support
    local reg = vim.fn.input("Register (default '+'): ", "+")
    if reg == "" then
      reg = "+"
    end
    reg = reg:sub(1, 1)

    -- Normalize line order
    if s_line > e_line then
      s_line, e_line = e_line, s_line
    end

    local lines = vim.api.nvim_buf_get_lines(0, s_line - 1, e_line, false)
    if not lines or #lines == 0 then
      return
    end

    local out = {}
    for i = 1, #lines, n do
      local line = lines[i] or ""
      -- Substring from the visual start column
      local content = line:sub(start_col)

      if delim ~= "" then
        local found = content:find(delim, 1, true)
        if found then
          content = content:sub(1, found - 1)
        end
      end
      table.insert(out, content)
    end

    if #out > 0 then
      local result = table.concat(out, "\n")
      -- 3. Set the register.
      -- Using 'v' as the third argument ensures it's treated as character-wise or block
      vim.fn.setreg(reg, result, "v")

      -- OPTIONAL: Also sync to unnamed register so 'p' works immediately
      vim.fn.setreg('"', result, "v")

      vim.notify(string.format("Yanked %d items into '%s'", #out, reg), vim.log.levels.INFO)
    else
      vim.notify("No content to yank", vim.log.levels.WARN)
    end
  end)
end, { noremap = true, silent = true, desc = "Yank every n-th slice to clipboard" })

if not detect_int_type then
  function detect_int_type()
    local line = vim.api.nvim_get_current_line()
    local t = line:match("([iu]%d+)")
    if t and t ~= "" then
      return t
    end
    local cw = vim.fn.expand("<cword>")
    t = cw:match("([iu]%d+)")
    if t and t ~= "" then
      return t
    end
    return "i64"
  end
end

local function trim(s)
  return (s or ""):match("^%s*(.-)%s*$")
end

local function is_integer_type(t)
  if not t then
    return false
  end
  t = trim(t)
  if t:match("^[iu]%d+$") then
    return true
  end
  if t == "isize" or t == "usize" then
    return true
  end
  return false
end

local function generate_rust_setter()
  local line = vim.api.nvim_get_current_line()
  local cur = vim.api.nvim_win_get_cursor(0)
  local row = cur[1] - 1

  -- 1. Parse "name: type,"
  local name, raw_type = line:match("^%s*([%w_]+)%s*:%s*(.-)%s*,?%s*$")
  if not name or not raw_type or raw_type == "" then
    vim.notify("Could not parse a field declaration on this line.", vim.log.levels.WARN)
    return
  end
  raw_type = trim(raw_type)

  -- 2. Detect Option<Inner>
  local inner = raw_type:match("^Option%s*<%s*(.-)%s*>$")
  local is_option = inner ~= nil
  if is_option then
    inner = trim(inner)
  end

  local indent = line:match("^(%s*)") or ""
  local fn_indent = indent .. "    "
  local fn_name = "set_" .. name

  local param_type, body_line

  if is_option then
    -- For Option<T>, we usually want to pass the Option directly
    param_type = "Option<" .. inner .. ">"
    body_line = "self." .. name .. " = value;"
  else
    -- Handle plain types
    if is_integer_type(raw_type) or raw_type == "bool" then
      param_type = raw_type
      body_line = "self." .. name .. " = value;"
    elseif raw_type == "String" then
      -- Using String here for simplicity; you could use &str and .to_string() if preferred
      param_type = "String"
      body_line = "self." .. name .. " = value;"
    else
      -- Generic fallback for custom types/structs
      param_type = raw_type
      body_line = "self." .. name .. " = value;"
    end
  end

  -- 3. Assemble the lines
  local lines = {
    indent .. "pub fn " .. fn_name .. "(&mut self, value: " .. param_type .. ") -> &mut Self {",
    fn_indent .. body_line,
    fn_indent .. "self",
    indent .. "}",
  }

  -- 4. Replace line and move cursor
  vim.api.nvim_buf_set_lines(0, row, row + 1, false, lines)
  local target_row = row + #lines
  if target_row >= vim.api.nvim_buf_line_count(0) then
    vim.api.nvim_buf_set_lines(0, -1, -1, false, { "" })
  end
  vim.api.nvim_win_set_cursor(0, { target_row + 1, 0 })

  vim.notify("Generated setter '" .. fn_name .. "'", vim.log.levels.INFO)
end

-- Map it to <leader>rs

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
  if is_option then
    inner = trim(inner)
  end

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
      ret_type = "&str"
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
    indent .. "}",
  }

  -- replace current line (row .. row+1) with function lines
  vim.api.nvim_buf_set_lines(0, row, row + 1, false, lines)

  -- compute target row (line immediately after final '}'), 0-indexed
  local target_row = row + #lines

  -- ensure there is at least one line after the inserted function; if not, append a blank line
  local line_count = vim.api.nvim_buf_line_count(0)
  if target_row >= line_count then
    vim.api.nvim_buf_set_lines(0, line_count, line_count, false, { "" })
    line_count = vim.api.nvim_buf_line_count(0)
  end

  -- put the cursor at the first column of the line after the function
  vim.api.nvim_win_set_cursor(0, { target_row + 1, 0 })

  vim.notify("Replaced field with getter '" .. fn_name .. "' -> " .. ret_type, vim.log.levels.INFO)
end

-- mapping (normal mode): <leader>rg to generate getter from current line
km({ "n" }, "<leader>rg", function()
  generate_rust_getter()
end, { noremap = true, silent = true, desc = "Generate Rust getter from field declaration (replace line)" })

km("n", "<Tab>", "<cmd>bnext<cr>", { desc = "Next Buffer" })

km("n", "<S-Tab>", "<cmd>bprevious<cr>", { desc = "Previous Buffer" })

km("n", "<leader>rs", generate_rust_setter, { noremap = true, silent = true, desc = "Generate Rust setter" })

-- vim.keymap.set("n", "<leader>pn", function()
-- 	local col = vim.fn.col(".")
-- 	local sw = vim.fn.shiftwidth()
-- 	vim.cmd("normal! " .. (col + sw) .. "|")
-- end, { desc = "Jump to next indent column" })
--
-- -- Jump backward one indent level horizontally
-- vim.keymap.set("n", "<leader>pp", function()
-- 	local col = vim.fn.col(".")
-- 	local sw = vim.fn.shiftwidth()
-- 	vim.cmd("normal! " .. math.max(1, col - sw) .. "|")
-- end, { desc = "Jump to prev indent column" })


vim.keymap.set("n","<leader>e", "<leader>fE", { desc = "Explorer Snacks (cwd)", remap = true})
vim.keymap.set("n","<leader>E", "<leader>fe", { desc = "Explorer Snacks (rwd)", remap = true})


vim.keymap.set("n", "<leader>tr", function()
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
    client:stop()
  end

  vim.cmd("edit")
  vim.notify("LSP restarted for Typst")
end, { desc = "Typst/LSP Restart" })


vim.keymap.set("n", "<leader>re", function()
    local win = vim.api.nvim_get_current_win()
    local cword = vim.fn.expand("<cword>")
    -- 1. Grab the full WORD under cursor (e.g., 'client_contacts::Column,')
    local full_prefix = vim.fn.expand("<cWORD>")
    -- Strip any trailing punctuation (like commas or brackets) from the end
    full_prefix = full_prefix:gsub("[^%w_:]+$", "")

    local clients = vim.lsp.get_clients({ bufnr = 0, name = "rust-analyzer" })
    if #clients == 0 then clients = vim.lsp.get_clients({ bufnr = 0 }) end

    local encoding = clients[1] and clients[1].offset_encoding or "utf-16"
    -- 2. Ask rust-analyzer for the definition location
    local params = vim.lsp.util.make_position_params(win, encoding)
    local responses = vim.lsp.buf_request_sync(0, "textDocument/definition", params, 2000)
    if not responses or vim.tbl_isempty(responses) then
        vim.notify("No LSP definition found", vim.log.levels.WARN)
        return
    end

    local result
    for _, resp in pairs(responses) do
        if resp.result and not vim.tbl_isempty(resp.result) then
            result = resp.result[1] or resp.result
            break
        end
    end

    if not result then return end

    -- 3. Load the target buffer (entity file) in the background
    local uri = result.uri or result.targetUri
    local bufnr = vim.uri_to_bufnr(uri)
    vim.fn.bufload(bufnr)
    local start_line = (result.range or result.targetSelectionRange).start.line
    -- Read the next 50 lines from the entity file to parse the variants
    local lines = vim.api.nvim_buf_get_lines(bufnr, start_line, start_line + 50, false)
    local variants = {}
    local inside_enum = false
    for _, l in ipairs(lines) do
        if l:match("enum%s+" .. cword) then
            inside_enum = true
        elseif inside_enum and l:match("^%s*}") then
            break
        elseif inside_enum then
            -- Match standard SeaORM enum variants (Capitalized, ignoring macros)
            local variant = l:match("^%s*([A-Z][%w_]*)%s*,?")
            if variant then
                -- Add variant without hardcoded spacing, formatting handles it later
                table.insert(variants, full_prefix .. "::" .. variant .. ",")
            end
        end
    end

    -- 4. Replace the current line and format
    if #variants > 0 then
        local r = vim.api.nvim_win_get_cursor(0)[1]
        -- Replace the current line (r - 1 to r) with the variants array
        vim.api.nvim_buf_set_lines(0, r - 1, r, false, variants)
        -- Move the cursor back into the inserted block and format inside the brackets
        vim.api.nvim_win_set_cursor(0, { r, 0 })
        vim.cmd("normal! vi[=")
        vim.notify("Filled " .. #variants .. " variants!", vim.log.levels.INFO)
    else
        vim.notify("Could not parse variants.", vim.log.levels.WARN)
    end
end, { desc = "Fill Enum Variants from LSP" })



vim.keymap.set("n", "<leader>se", "<cmd>Telescope lsp_document_symbols<cr>", { desc = "Document Symbols"})
vim.keymap.set("n", "<leader>sE", "<cmd>Telescope current_buffer_fuzzy_find<cr>", { desc = "Buffer Find"})
vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], {desc = "Exit Terminal Mode"})
vim.keymap.set("n", "<leader>tt", "<cmd>terminal powershell.exe<cr>", {desc = "Open Powershell Terminal"})


-- Shared helper to query LSP and parse a struct's fields
local function get_struct_fields()
    local win = vim.api.nvim_get_current_win()
    local cword = vim.fn.expand("<cword>")

    local clients = vim.lsp.get_clients({ bufnr = 0, name = "rust-analyzer" })
    if #clients == 0 then clients = vim.lsp.get_clients({ bufnr = 0 }) end

    local encoding = clients[1] and clients[1].offset_encoding or "utf-16"
    local params = vim.lsp.util.make_position_params(win, encoding)
    local responses = vim.lsp.buf_request_sync(0, "textDocument/definition", params, 2000)
    if not responses or vim.tbl_isempty(responses) then
        vim.notify("No LSP definition found", vim.log.levels.WARN)
        return nil, nil
    end

    local result
    for _, resp in pairs(responses) do
        if resp.result and not vim.tbl_isempty(resp.result) then
            result = resp.result[1] or resp.result
            break
        end
    end

    if not result then return nil, nil end

    local uri = result.uri or result.targetUri
    local bufnr = vim.uri_to_bufnr(uri)
    vim.fn.bufload(bufnr)
    local start_line = (result.range or result.targetSelectionRange).start.line
    -- Read 50 lines down from the struct definition
    local lines = vim.api.nvim_buf_get_lines(bufnr, start_line, start_line + 50, false)
    
    local fields = {}
    local inside_struct = false
    for _, l in ipairs(lines) do
        if l:match("struct%s+" .. cword) then
            inside_struct = true
        elseif inside_struct and l:match("^%s*}") then
            break
        elseif inside_struct then
            local line_clean = l:gsub("^%s*", ""):gsub("%s*//.*$", "") -- Trim and remove comments
            if not line_clean:match("^#") and line_clean ~= "" then
                -- Strip out visibility modifiers like pub, pub(crate), pub(in self)
                local standard_line = line_clean:gsub("^pub%s*%b()%s*", ""):gsub("^pub%s*", "")
                local f_name, f_type = standard_line:match("^([%w_]+)%s*:%s*(.+)$")
                if f_name then
                    f_type = f_type:gsub(",%s*$", "") -- Strip trailing comma
                    local is_option = f_type:match("Option%s*<") ~= nil
                    table.insert(fields, { name = f_name, is_option = is_option })
                end
            end
        end
    end
    return cword, fields
end

-- 1. Builder Generation (<leader>rb)
vim.keymap.set("n", "<leader>rb", function()
    local cword, fields = get_struct_fields()
    if not fields or #fields == 0 then
        vim.notify("Could not parse struct fields.", vim.log.levels.WARN)
        return
    end

    -- bon uses StructName::builder() for associated builders
    local lines_to_insert = { cword .. "::builder()" }
    for _, f in ipairs(fields) do
        if f.is_option then
            table.insert(lines_to_insert, "    ." .. f.name .. "(Some(" .. f.name .. "))")
        else
            table.insert(lines_to_insert, "    ." .. f.name .. "(" .. f.name .. ")")
        end
    end
    table.insert(lines_to_insert, "    .build()")

    local r = vim.api.nvim_win_get_cursor(0)[1]
    vim.api.nvim_buf_set_lines(0, r - 1, r, false, lines_to_insert)
    
    -- Format the inserted block
    vim.api.nvim_win_set_cursor(0, { r, 0 })
    vim.cmd("normal! =" .. #lines_to_insert .. "_")
    vim.notify("Generated builder for " .. cword, vim.log.levels.INFO)
end, { desc = "Generate bon::Builder implementation" })


-- 2. Dissolve Generation (<leader>rd) [Updated for multi-line layout]
vim.keymap.set("n", "<leader>rd", function()
    local cword, fields = get_struct_fields()
    if not fields or #fields == 0 then
        vim.notify("Could not parse struct fields.", vim.log.levels.WARN)
        return
    end

    -- Intelligently guess the instance variable name by converting PascalCase to snake_case
    local instance_name = cword:gsub("([a-z0-9])([A-Z])", "%1_%2"):lower()
    
    -- Build the multi-line destructuring statement
    local lines_to_insert = { "let (" }
    for _, f in ipairs(fields) do
        table.insert(lines_to_insert, "    " .. f.name .. ",")
    end
    table.insert(lines_to_insert, ") = " .. instance_name .. ".dissolve();")

    local r = vim.api.nvim_win_get_cursor(0)[1]
    vim.api.nvim_buf_set_lines(0, r - 1, r, false, lines_to_insert)
    
    -- Format the entire newly inserted block
    vim.api.nvim_win_set_cursor(0, { r, 0 })
    vim.cmd("normal! =" .. #lines_to_insert .. "_")
    vim.notify("Generated multi-line dissolve for " .. cword, vim.log.levels.INFO)
end, { desc = "Generate bon dissolve destructuring (multi-line)" })



local function trash_current_file()
  local file = vim.api.nvim_buf_get_name(0)

  if file == "" then
    vim.notify("No file name for current buffer", vim.log.levels.WARN)
    return
  end

  if vim.bo.modified then
    vim.notify("Buffer has unsaved changes. Save first.", vim.log.levels.WARN)
    return
  end

  local confirm = vim.fn.confirm(
    "Move this file to local trash?",
    "&Yes\n&No",
    2
  )

  if confirm ~= 1 then
    return
  end

  local trash_dir = vim.fn.stdpath("state") .. "/trash"
  vim.fn.mkdir(trash_dir, "p")

  local name = vim.fn.fnamemodify(file, ":t")
  local ts = os.date("%Y%m%d-%H%M%S")
  local dest = trash_dir .. "/" .. ts .. "-" .. name

  local ok, err = pcall(vim.fn.rename, file, dest)
  if not ok or err ~= 0 then
    vim.notify("Failed to move file to trash", vim.log.levels.ERROR)
    return
  end

  vim.cmd("bd!")
  vim.notify("Moved to trash: " .. dest, vim.log.levels.INFO)
end

vim.keymap.set("n", "<leader>qD", trash_current_file, { desc = "Trash current file and quit" })

vim.keymap.set("n", "<leader>fa", "<cmd>FlutterAttach --dart-define-from-file=env.dev.json<cr>", { desc = "Flutter Attach With Env"})


vim.keymap.set("n", "<leader>cA", "<cmd>RustOrganizeImports<cr>", {desc = "Source Code Action Rust Organize Imports", remap = true})
