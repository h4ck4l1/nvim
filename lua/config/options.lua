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
    vim.opt_local.expandtab = true    -- Use spaces, not tabs
    vim.opt_local.tabstop = 2         -- Render tabs as 2 spaces
    vim.opt_local.shiftwidth = 2      -- Indent steps are 2 spaces
    vim.opt_local.softtabstop = 2     -- Backspace deletes 2 spaces
    -- Overrides global autoformat option for the current buffer
    vim.b.autoformat = false
  end,
})

opt.fileformat = "unix"
opt.fileformats = "unix"
opt.fixeol = true
opt.cursorline = false

vim.opt.autoread = true
vim.opt.inccommand = "nosplit"

