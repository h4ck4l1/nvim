local M = {}

-- Splits a string into lowercase tokens based on caps, dashes, underscores, and dots
local function tokenize(str)
  local s = str:gsub("([^%u%s%-_%.])(%u)", "%1 %2")
                :gsub("(%u)(%u%l)", "%1 %2")
                :gsub("[%-_%.]", " ")
  local tokens = {}
  for word in s:gmatch("%S+") do
    table.insert(tokens, word:lower())
  end
  return tokens
end

-- Case formatters
local formatters = {
  s = function(tokens) return table.concat(tokens, "_") end,
  l = function(_, cword) return cword:lower() end,
  u = function(tokens) return table.concat(tokens, "_"):upper() end,
  ["-"] = function(tokens) return table.concat(tokens, "-") end,
  ["."] = function(tokens) return table.concat(tokens, ".") end,
  c = function(tokens)
    if #tokens == 0 then return "" end
    local res = tokens[1]
    for i = 2, #tokens do
      res = res .. tokens[i]:gsub("^%l", string.upper)
    end
    return res
  end,
  m = function(tokens)
    local res = ""
    for i = 1, #tokens do
      res = res .. tokens[i]:gsub("^%l", string.upper)
    end
    return res
  end,
}

function M.coerce(case_mode)
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local line = vim.api.nvim_get_current_line()
  local cursor_byte = col + 1

  local start_idx, end_idx
  local start_search = 1
  while true do
    local s, e = line:find("[%w_%.%-]+", start_search)
    if not s then break end
    if cursor_byte >= s and cursor_byte <= e then
      start_idx, end_idx = s, e
      break
    end
    start_search = e + 1
  end

  if not start_idx then return end

  local cword = line:sub(start_idx, end_idx)
  local tokens = tokenize(cword)
  if #tokens == 0 then return end

  local formatter = formatters[case_mode]
  if not formatter then return end

  local new_word = formatter(tokens, cword)
  if new_word == cword then return end

  vim.api.nvim_buf_set_text(0, row - 1, start_idx - 1, row - 1, end_idx, { new_word })

  local relative_offset = cursor_byte - start_idx
  local new_col = start_idx - 1 + math.min(relative_offset, math.max(0, #new_word - 1))
  vim.api.nvim_win_set_cursor(0, { row, new_col })
end

-- Helper function to match the casing of the target string
function _G.preserve_case(match, replacement)
  if match == match:upper() then
    return replacement:upper()
  elseif match == match:lower() then
    return replacement:lower()
  elseif match:sub(1, 1) == match:sub(1, 1):upper() then
    return replacement:sub(1, 1):upper() .. replacement:sub(2):lower()
  else
    return replacement
  end
end

-- Custom :S user command for case-preserving substitution with live preview
vim.api.nvim_create_user_command("S", function(opts)
  local args = opts.args
  if #args < 3 then
    vim.notify("Usage: :S/search/replace/[flags]", vim.log.levels.ERROR)
    return
  end

  local delim = args:sub(1, 1)
  local parts = vim.split(args:sub(2), delim, { plain = true })

  local search = parts[1]
  local replace = parts[2]
  local flags = parts[3] or "g"

  if not search or not replace then
    vim.notify("Usage: :S" .. delim .. "search" .. delim .. "replace" .. delim .. "[flags]", vim.log.levels.ERROR)
    return
  end

  local replace_escaped = replace:gsub("'", "''")

  local cmd = string.format(
    "%d,%ds%s\\c%s%s\\=v:lua.preserve_case(submatch(0), '%s')%s%s",
    opts.line1, opts.line2,
    delim, search, delim, replace_escaped, delim, flags
  )

  local ok, err = pcall(vim.cmd, cmd)
  if not ok then
    vim.notify("Substitution error: " .. tostring(err), vim.log.levels.ERROR)
  end
end, {
  range = "%",
  nargs = 1,
  preview = function(opts, ns_id, bufnr)
    local args = opts.args
    if #args < 2 then return 0 end

    local delim = args:sub(1, 1)
    local parts = vim.split(args:sub(2), delim, { plain = true })

    local search = parts[1]
    local replace = parts[2]
    local flags = parts[3] or "g"

    if not search or search == "" then return 0 end

    -- bufnr argument is the preview split buffer. We need the target editing buffer.
    local target_buf = vim.api.nvim_get_current_buf()

    -- 1. Highlight search term matches while typing search term
    if #parts < 2 then
      local ok, re = pcall(vim.regex, "\\c" .. search)
      if not ok or not re then return 0 end

      local lines = vim.api.nvim_buf_get_lines(target_buf, opts.line1 - 1, opts.line2, false)
      for i, line in ipairs(lines) do
        local line_idx = opts.line1 - 1 + i - 1
        local col = 0
        while col < #line do
          local s, e = re:match_str(line:sub(col + 1))
          if not s then break end
          vim.api.nvim_buf_add_highlight(target_buf, ns_id, "IncSearch", line_idx, col + s, col + e)
          col = col + (e > s and e or 1)
        end
      end
      return 1
    end

    -- 2. Preview live substitution changes while typing replacement
    local replace_escaped = replace:gsub("'", "''")
    local cmd = string.format(
      "%d,%ds%s\\c%s%s\\=v:lua.preserve_case(submatch(0), '%s')%s%s",
      opts.line1, opts.line2,
      delim, search, delim, replace_escaped, delim, flags
    )

    -- Capture original lines before running the substitution to trace positions
    local original_lines = vim.api.nvim_buf_get_lines(target_buf, opts.line1 - 1, opts.line2, false)

    -- Speculatively perform the substitution
    local ok = pcall(vim.cmd, cmd)
    if not ok then return 0 end

    -- Capture the modified lines after substitution
    local modified_lines = vim.api.nvim_buf_get_lines(target_buf, opts.line1 - 1, opts.line2, false)

    local ok_re, re = pcall(vim.regex, "\\c" .. search)
    if ok_re and re then
      local preserve_case_fn = _G.preserve_case or function(str, pat) return pat end
      local preview_lines = {}
      local preview_highlights = {}
      local preview_buf_line = 0

      for i, line in ipairs(original_lines) do
        local line_idx = opts.line1 - 1 + i - 1
        local col = 0
        local shift = 0
        local line_has_match = false
        local matches = {}

        -- Locate match boundaries in original text and map them to their new shifted positions
        while col < #line do
          local s, e = re:match_str(line:sub(col + 1))
          if not s then break end

          local orig_start = col + s
          local orig_end = col + e
          local matched_text = line:sub(orig_start + 1, orig_end)
          local replacement = preserve_case_fn(matched_text, replace)

          local new_start = orig_start + shift
          local new_end = new_start + #replacement

          table.insert(matches, {
            new_start = new_start,
            new_end = new_end,
          })

          shift = shift + (#replacement - #matched_text)
          col = col + (e > s and e or 1)
          line_has_match = true
        end

        -- Add highlights to the main (target) buffer
        for _, m in ipairs(matches) do
          vim.api.nvim_buf_add_highlight(target_buf, ns_id, "Substitute", line_idx, m.new_start, m.new_end)
        end

        -- If split preview is active, store corresponding lines and highlights
        if bufnr and line_has_match then
          local modified_line = modified_lines[i] or ""
          local prefix = string.format("|%d| ", line_idx + 1)
          table.insert(preview_lines, prefix .. modified_line)

          for _, m in ipairs(matches) do
            table.insert(preview_highlights, {
              line = preview_buf_line,
              start_col = #prefix + m.new_start,
              end_col = #prefix + m.new_end,
            })
          end
          preview_buf_line = preview_buf_line + 1
        end
      end

      -- Populate the split buffer if it exists and matches were found
      if bufnr and #preview_lines > 0 then
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, preview_lines)
        for _, hl in ipairs(preview_highlights) do
          vim.api.nvim_buf_add_highlight(bufnr, ns_id, "Substitute", hl.line, hl.start_col, hl.end_col)
        end
      end
    end

    return (vim.o.inccommand == "split") and 2 or 1
  end,
})

-- Return a valid lazy.nvim plugin spec
return {
  "custom-coercion",
  dir = vim.fn.stdpath("config"),

  keys = {
    { "crs", function() M.coerce("s") end, desc = "Snake Case" },
    { "crc", function() M.coerce("c") end, desc = "Camel Case" },
    { "crm", function() M.coerce("m") end, desc = "Pascal Case" },
    { "cru", function() M.coerce("u") end, desc = "Upper Case" },
    { "crl", function() M.coerce("l") end, desc = "Lower Case" },
    { "cr-", function() M.coerce("-") end, desc = "Kebab Case" },
    { "cr.", function() M.coerce(".") end, desc = "Dot Case" },
  },

  init = function()
    pcall(function()
      require("which-key").add({
        { "cr", group = "Coerce Case", mode = "n" },
      })
    end)
  end,
}
