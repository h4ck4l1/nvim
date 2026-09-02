-- -- Options are automatically loaded before lazy.nvim startup
-- -- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- -- Add any additional options here
--
-- local opt = vim.opt
--
-- opt.expandtab = false
-- opt.tabstop = 4
-- opt.shiftwidth = 4 -- 0 previous
-- opt.softtabstop = 4 -- 1 previous
-- opt.autoindent = true
--
--
--
-- vim.g.autoformat = false
-- -- vim.g.minipairs_disable = true
-- -- vim.g.lazyvim_lsp_inlay_hints = false
--
-- vim.api.nvim_create_autocmd("FileType", {
--   pattern = "dart",
--   callback = function()
--     vim.opt_local.expandtab = true
--     vim.opt_local.tabstop = 2
--     vim.opt_local.shiftwidth = 2
--     vim.opt_local.softtabstop = 2
--     vim.b.autoformat = false
--
--     vim.schedule(function()
--       local current_expr = vim.bo.indentexpr
--       if current_expr ~= "" and not current_expr:match("DartSmartIndent") then
--         vim.b.orig_indentexpr = current_expr
--
--         _G.DartSmartIndent = function()
--           local ok, ts_indent = pcall(vim.fn.eval, vim.b.orig_indentexpr)
--           if not ok or type(ts_indent) ~= "number" then
--             ts_indent = vim.fn.cindent(vim.v.lnum)
--           end
--
--           local prev_lnum = vim.fn.prevnonblank(vim.v.lnum - 1)
--           if prev_lnum == 0 then return ts_indent end
--
--           local current_line = vim.fn.getline(vim.v.lnum)
--
--           -- 1. THE ULTIMATE FIX: If we are on a closing bracket line, 
--           -- MANUALLY find its matching opening line and copy its indentation!
--           local closing_match = current_line:match("^%s*([%)%}%]])")
--           if closing_match then
--             local opening_map = { [")"] = "(", ["}"] = "{", ["]"] = "[" }
--             local open_bracket = opening_map[closing_match]
--
--             -- Save view to temporarily move the cursor without you noticing
--             local saved_view = vim.fn.winsaveview()
--
--             -- Move cursor to the exact closing bracket on this line
--             local col = string.find(current_line, closing_match, 1, true)
--             vim.fn.cursor(vim.v.lnum, col)
--
--             -- Find the matching opening bracket using Vim's rock-solid syntax engine
--             local open_lnum = vim.fn.searchpair(
--               '\\V' .. open_bracket, '', '\\V' .. closing_match, 'bW'
--             )
--
--             local correct_indent = ts_indent
--             if open_lnum > 0 then
--               correct_indent = vim.fn.indent(open_lnum)
--             end
--
--             -- Restore cursor and return the matching line's indentation
--             vim.fn.winrestview(saved_view)
--             return correct_indent
--           end
--
--           -- 2. Safety Net: Check if the previous line opened a block
--           local prev_line = vim.fn.getline(prev_lnum)
--           local prev_code = prev_line:gsub("//.*", ""):gsub("%s+$", "")
--
--           -- If previous line ended in {, (, or [
--           if prev_code:match("[%(%{%[]$") then
--             local prev_indent = vim.fn.indent(prev_lnum)
--             -- If Treesitter hit its bug and didn't indent, we FORCE it forward
--             if ts_indent <= prev_indent then
--               return prev_indent + vim.fn.shiftwidth()
--             end
--           end
--
--           -- 3. For standard lines inside a block, trust Treesitter!
--           return ts_indent
--         end
--
--         vim.bo.indentexpr = "v:lua.DartSmartIndent()"
--       end
--     end)
--   end,
-- })
--
-- -- vim.api.nvim_create_autocmd("FileType", {
-- --   pattern = "dart",
-- --   callback = function()
-- --     vim.opt_local.expandtab = true    -- Use spaces, not tabs
-- --     vim.opt_local.tabstop = 2         -- Render tabs as 2 spaces
-- --     vim.opt_local.shiftwidth = 2      -- Indent steps are 2 spaces
-- --     vim.opt_local.softtabstop = 2     -- Backspace deletes 2 spaces
-- --     -- Overrides global autoformat option for the current buffer
-- --     vim.b.autoformat = false
-- --   end,
-- -- })
--
-- opt.fileformat = "unix"
-- opt.fileformats = "unix"
-- opt.fixeol = true
-- opt.cursorline = false
--
-- vim.opt.autoread = true
-- vim.opt.inccommand = "nosplit"
--
-- -- Ensure Neovim explicitly saves folds, cursor position, and the current directory in its views
-- vim.opt.viewoptions = { "folds", "cursor", "curdir" }


-- Options are automatically loaded before lazy.nvim startup
local opt = vim.opt

-- Indentation (Tabs by default)
opt.expandtab = false
opt.tabstop = 4
opt.shiftwidth = 4
opt.softtabstop = 4
opt.autoindent = true

-- Behavior & Formatting
vim.g.autoformat = false
opt.cursorline = false
opt.autoread = true
opt.inccommand = "nosplit"
-- opt.guicursor = "n-v-c-sm:block,i-ci-ve:hor20,r-cr-o:hor20"

-- File encoding & Views
opt.fileformat = "unix"
opt.fileformats = "unix"
opt.fixeol = true
opt.viewoptions = { "folds", "cursor", "curdir" }
