-- add to your plugins list
return {
  {
    "nvim-pack/nvim-spectre", -- or "windwp/nvim-spectre" (same repo)
    dependencies = { "nvim-lua/plenary.nvim" },
    cmd = "Spectre",
    keys = {
      { "<leader>S",  "<cmd>lua require('spectre').toggle()<CR>", desc = "Toggle Spectre" },
      { "<leader>sw", "<cmd>lua require('spectre').open_visual({select_word=true})<CR>", mode = { "n", "v" }, desc = "Search word (visual)" },
      { "<leader>sp", "<cmd>lua require('spectre').open_file_search({select_word=true})<CR>", desc = "Search in current file" },
    },
    config = function()
      require("spectre").setup({
        color_devicons = true,
        open_cmd = "vnew",    -- or "tabnew", or a lua function
        live_update = false,  -- set true to auto-update on writes
        -- keep other defaults unless you need to tweak mappings or engines
      })
    end,
  },
}
