

return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      emmet_ls = {
        filetypes = {
          "html",
          "css",
          "scss",
          "sass",
          "less",
          "pug",
        },
      },
    },
  },
}
