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
				mapping = {
					['toggle_ignore_case'] = {
						map = "ti",
						cmd = "<cmd>lua require('spectre').change_options('ignore-case')<CR>",
						desc = "toggle ignore case"
					},
					['toggle_ignore_hidden'] = {
						map = "th",
						cmd = "<cmd>lua require('spectre').change_options('hidden')<CR>",
						desc = "toggle search hidden"
					},
					['toggle_fixed_strings'] = {
						map = "tf",
						cmd = "<cmd>lua require('spectre').change_options('fixed-strings')<CR>",
						desc = "toggle fixed strings (literal)"
					},
					['toggle_word_regexp'] = {
						map = "tw",
						cmd = "<cmd>lua require('spectre').change_options('word-regexp')<CR>",
						desc = "toggle word regexp"
					},
					['toggle_no_ignore'] = {
						map = "tg",
						cmd = "<cmd>lua require('spectre').change_options('no-ignore')<CR>",
						desc = "toggle search gitignored"
					}
				}
			})
		end,
	},
}
