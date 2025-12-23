

return {
	{
		"navarasu/onedark.nvim",
		priority = 1000,
		config = function()
			require('onedark').setup {
				style = 'darker'
			}
			require('onedark').load()
		end
	}
}
--
--
-- return {
-- 	{
-- 		"olimorris/onedarkpro.nvim",
-- 		priority = 1000, -- load early so colorscheme can be set safely
-- 		config = function()
-- 			-- minimal custom setup (optional)
-- 			require("onedarkpro").setup({
-- 				-- only include fields you want to override — empty setup uses defaults
-- 				styles = {
-- 					comments = "italic",
-- 					keywords = "bold",
-- 				},
-- 				-- enable/disable built-in filetype/plugin groups if you want
-- 				plugins = {
-- 					gitsigns = true,
-- 					telescope = true,
-- 					nvim_tree = true,
-- 				},
-- 			})
-- 			-- pick a variant: "onedark" is the default; others: "onelight", "onedark_vivid", "vaporwave", "onedark_dark"
-- 			vim.cmd("colorscheme onedark_dark")
-- 		end,
-- 	}
-- }
