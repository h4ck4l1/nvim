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
					fg = "#7aa2f7",       -- Soft light blue/white text
					gray = "#3b4261",     -- Darker gray for comments
					red = "#1a86ad",      -- Soft red (Actually teal, used for variables)
					green = "#9ece6a",    -- Pastel green
					yellow = "#e0af68",   -- Soft yellow
					blue = "#8f6ff7",     -- Bright blue
					purple = "#bb9af7",   -- Soft purple
					cyan = "#7dcfff",     -- Bright cyan
					cursorline = "#1a1b26", -- Background color of the line you are on
				},

				-- 2. Customize how specific code elements are styled
				highlights = {
					Comment = { fg = "#565f89", style = "italic" },
					Keyword = { fg = "#bb9af7", style = "bold" },
					Function = { fg = "#7aa2f7" },
					String = { fg = "#9ece6a" },
					Constant = { fg = "#ff9e64" },
					CursorLineNr = { fg = "#7dcfff", style = "bold" },
					LineNr = { fg = "#3b4261" },

					-- 1. Make standard variable references standard text color (#c0caf5)
					["@variable"] = { fg = "${fg}" },
					["@lsp.type.variable"] = { fg = "${fg}" },

					-- 2. Keep variable declarations highlighted in your custom cyan (${red})
					["@lsp.typemod.variable.declaration"] = { fg = "${red}" },
					["@lsp.typemod.variable.declaration.dart"] = { fg = "${red}" },

					-- ==========================================
					-- 3. EXPLICITLY MAKE ERRORS ACTUAL RED
					-- ==========================================
					DiagnosticError = { fg = "#f7768e" }, -- Base error color
					DiagnosticSignError = { fg = "#f7768e" }, -- Error sign in the gutter
					DiagnosticVirtualTextError = { fg = "#f7768e" }, -- Virtual text at the end of the line
					DiagnosticUnderlineError = { sp = "#f7768e", style = "undercurl" }, -- Squiggly underline
					Error = { fg = "#f7768e" }, -- General editor errors
					ErrorMsg = { fg = "#f7768e" }, -- Command line error messages
				},

				-- 3. Adjust general styles easily
				styles = {
					types = "NONE",
					methods = "bold,italic",
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
					transparency = true,
				}
			})

			-- 4. Load your preferred variant
			vim.cmd("colorscheme onedark") 
		end,
	},
}
