-- Only disable heavy background engines if READONLY_MODE=1 is set in your environment
if vim.env.READONLY_MODE == "1" then
  return {
    -- 1. Disable LSP (Stops tsserver, gopls, etc.)
    { "neovim/nvim-lspconfig", enabled = false },
    -- 🚨 THE FIX: Disable dedicated LSP managers that bypass lspconfig!
    { "mrcjkb/rustaceanvim", enabled = false },
    { "williamboman/mason-lspconfig.nvim", enabled = false }, -- (Optional) good safety measure

    -- 2. Disable Linters & Diagnostics engines
    { "mfussenegger/nvim-lint", enabled = false },

    -- 3. Disable Auto-completion popups (not needed since we can't type)
    { "hrsh7th/nvim-cmp", enabled = false },
    { "saghen/blink.cmp", enabled = false },
  }
end

-- Normal editing mode: keep everything active
return {}
