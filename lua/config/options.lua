-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

local opt = vim.opt

opt.expandtab = false
opt.tabstop = 4
opt.shiftwidth = 4    -- 0 previous
opt.softtabstop = 4   -- 1 previous
opt.autoindent = true
vim.g.autoformat = false
vim.g.minipairs_disable = true
opt.cursorline = false


local ok, lspconfig = pcall(require, "lspconfig")
if not ok then
  return
end

-- Keep Emmet for HTML/CSS-ish filetypes only — remove it from jsx/tsx
lspconfig.emmet_ls.setup {
  filetypes = {
    "html",
    "css",
    "scss",
    "sass",
    "less",
    "pug",
    -- add more html-like types if you want emmet there
  },
}
