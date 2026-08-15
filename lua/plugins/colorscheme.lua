-- return {
-- 	{
-- 		"olimorris/onedarkpro.nvim",
-- 		priority = 1000,
-- 		config = function()
-- 			require("onedarkpro").setup({
-- 				options = {
-- 					transparency = false
-- 				}
-- 			})
-- 			vim.cmd("colorscheme vaporwave")
-- 		end,
-- 	},
-- }
return {
  {
    "olimorris/onedarkpro.nvim",
    priority = 1000,
    config = function()
      require("onedarkpro").setup({
        -- 1. Override the core color palette
        colors = {
          -- You can override colors globally for all themes:
          -- red = "#ff5555",
          -- blue = "#8be9fd",

          -- Or target a specific theme variant (e.g., "onedark" or "onedark_vivid"):
          onedark = {
            bg = "#1e1e2e", -- Custom background (e.g., a warmer deep charcoal/blue)
            fg = "#cdd6f4", -- Custom foreground text
            purple = "#f5c2e7",
            blue = "#89b4fa",
            green = "#a6e3a1",
            yellow = "#f9e2af",
            red = "#f38ba8",
          },
          onedark_vivid = {
            bg = "#181825", -- Deep dark background for the vivid variant
          }
        },

        -- 2. Customize how specific code elements are styled
        highlights = {
          -- You can reference custom palette colors using "${color_name}"
          Comment = { fg = "#6c7086", style = "italic" },
          ["@keyword"] = { fg = "${purple}", style = "bold" },
          ["@variable"] = { fg = "${fg}" },
          ["@function"] = { fg = "${blue}", style = "bold" },
          ["@string"] = { fg = "${green}" },
          -- Modify UI elements if desired
          CursorLine = { bg = "#2e313f" },
        },

        -- 3. Adjust general styles easily
        styles = {
          types = "NONE",
          methods = "NONE",
          numbers = "NONE",
          strings = "NONE",
          comments = "italic",
          keywords = "bold",
          constants = "NONE",
          functions = "NONE",
          operators = "NONE",
          variables = "NONE",
          parameters = "NONE",
          conditionals = "NONE",
          virtual_text = "NONE",
        },

        options = {
          transparency = false,
        }
      })

      -- 4. Load your preferred variant
      -- Available built-in variants:
      -- "onedark" | "onelight" | "onedark_vivid" | "onedark_dark" | "vaporwave"
      vim.cmd("colorscheme onedark_vivid")
    end,
  },
}
