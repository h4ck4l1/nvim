return {

	{
		"olimorris/onedarkpro.nvim",
		priority = 1000,
	},
	{
		"tiagovla/tokyodark.nvim",
		opts = {

		},
		config = function(_, opts)
			require("tokyodark").setup(opts) -- calling setup is optional
			vim.cmd [[colorscheme tokyodark]]
		end,
	},
	{
		"eldritch-theme/eldritch.nvim",
		lazy = false,
		priority = 1000,
		opts = {},

	},
	{
		'maxmx03/fluoromachine.nvim',
		lazy = false,
		priority = 1000,
		config = function ()
			local fm = require 'fluoromachine'
			fm.setup {
				glow = true,
				theme = 'fluoromachine',
				transparent = true,
			}
			vim.cmd.colorscheme 'fluoromachine'
		end
	},
	{
		"navarasu/onedark.nvim",
		priority = 1000,
		config = function()
			require('onedark').setup  {
				style = 'dark', -- Default theme style. Choose between 'dark', 'darker', 'cool', 'deep', 'warm', 'warmer' and 'light'
				transparent = false,  -- Show/hide background
				term_colors = true, -- Change terminal color as per the selected theme style
				ending_tildes = false, -- Show the end-of-buffer tildes. By default they are hidden
				cmp_itemkind_reverse = false, -- reverse item kind highlights in cmp menu

				toggle_style_key = "<leader>ts", -- keybind to toggle theme style. Leave it nil to disable it, or set it to a string, for example "<leader>ts"
				toggle_style_list = {'dark', 'darker', 'cool', 'deep', 'warm', 'warmer', 'light'}, -- List of styles to toggle between

				code_style = {
					comments = 'italic',
					keywords = 'none',
					functions = 'none',
					strings = 'none',
					variables = 'none'
				},

				lualine = {
					transparent = false, -- lualine center bar transparency
				},

				colors = {}, -- Override default colors
				highlights = {}, -- Override highlight groups

				diagnostics = {
					darker = true, -- darker colors for diagnostic
					undercurl = true,   -- use undercurl instead of underline for diagnostics
					background = true,    -- use background color for virtual text
				},
			}
		end
	},
	{
		"LazyVim/LazyVim",
		opts = {
			colorscheme = "onedark",
		},
	},
}
