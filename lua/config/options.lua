-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

local opt = vim.opt

opt.expandtab = false
opt.tabstop = 4
opt.shiftwidth = 4 -- 0 previous
opt.softtabstop = 4 -- 1 previous
opt.autoindent = true



vim.g.autoformat = false
-- vim.g.minipairs_disable = true
-- vim.g.lazyvim_lsp_inlay_hints = false

vim.api.nvim_create_autocmd("FileType", {
  pattern = "dart",
  callback = function()
    vim.opt_local.expandtab = true
    vim.opt_local.tabstop = 2
    vim.opt_local.shiftwidth = 2
    vim.opt_local.softtabstop = 2
    vim.b.autoformat = false
    vim.schedule(function()
      local current_expr = vim.bo.indentexpr
      if current_expr ~= "" and not current_expr:match("DartSmartIndent") then
        vim.b.orig_indentexpr = current_expr
        _G.DartSmartIndent = function()
          -- 1. Ask Treesitter what it thinks (It's perfect for Widgets!)
          local ok, ts_indent = pcall(vim.fn.eval, vim.b.orig_indentexpr)
          if not ok then ts_indent = vim.fn.cindent(vim.v.lnum) end
          local prev_lnum = vim.fn.prevnonblank(vim.v.lnum - 1)
          if prev_lnum == 0 then return ts_indent end
          local prev_line = vim.fn.getline(prev_lnum)
          local current_line = vim.fn.getline(vim.v.lnum)
          -- 2. If this line is a closing '}', cindent calculates it perfectly.
          if current_line:match("^%s*}") then
            return vim.fn.cindent(vim.v.lnum)
          end
          -- 3. Check if the previous line opened a block
          -- We strip trailing comments to safely find the '{'
          local prev_code = prev_line:gsub("//.*", ""):gsub("%s+$", "")
          if prev_code:match("{$") then
            local prev_indent = vim.fn.indent(prev_lnum)
            -- If Treesitter hit its bug and failed to indent, we FORCE it forward.
            if ts_indent <= prev_indent then
              return prev_indent + vim.fn.shiftwidth()
            end
          end
          -- 4. For everything else (Widgets, lists, etc), strictly trust Treesitter!
          return ts_indent
        end
        vim.bo.indentexpr = "v:lua.DartSmartIndent()"
      end
    end)
  end,
})

-- vim.api.nvim_create_autocmd("FileType", {
--   pattern = "dart",
--   callback = function()
--     vim.opt_local.expandtab = true    -- Use spaces, not tabs
--     vim.opt_local.tabstop = 2         -- Render tabs as 2 spaces
--     vim.opt_local.shiftwidth = 2      -- Indent steps are 2 spaces
--     vim.opt_local.softtabstop = 2     -- Backspace deletes 2 spaces
--     -- Overrides global autoformat option for the current buffer
--     vim.b.autoformat = false
--   end,
-- })

opt.fileformat = "unix"
opt.fileformats = "unix"
opt.fixeol = true
opt.cursorline = false

vim.opt.autoread = true
vim.opt.inccommand = "nosplit"

-- Ensure Neovim explicitly saves folds, cursor position, and the current directory in its views
vim.opt.viewoptions = { "folds", "cursor", "curdir" }
