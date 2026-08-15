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
					bg = "#0f1117",       -- Dark blue/black background
					fg = "#c0caf5",       -- Soft light blue/white text
					gray = "#3b4261",     -- Darker gray for comments
					red = "#f7768e",      -- Soft red
					green = "#9ece6a",    -- Pastel green
					yellow = "#e0af68",   -- Soft yellow
					blue = "#7aa2f7",     -- Bright blue
					purple = "#bb9af7",   -- Soft purple
					cyan = "#7dcfff",     -- Bright cyan
					cursorline = "#1a1b26", -- Background color of the line you are on
				},

				-- 2. Customize how specific code elements are styled
				highlights = {
					Comment = { fg = "#565f89", style = "italic" }, -- Make comments darker and italic
					Keyword = { fg = "#bb9af7", style = "bold" },   -- Make keywords (function, if, etc) bold purple
					Function = { fg = "#7aa2f7" },                   -- Function names bright blue
					String = { fg = "#9ece6a" },                    -- Strings pastel green
					Constant = { fg = "#ff9e64" },                  -- Constants (numbers, true/false) orange
					CursorLineNr = { fg = "#7dcfff", style = "bold" }, -- Line number color
					LineNr = { fg = "#3b4261" },                     -- Other line numbers
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
			vim.cmd("colorscheme onedark") 
		end,
	},
}
