return {
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		main = "nvim-treesitter.configs",
		opts = {
			ensure_installed = {
				"lua",
				"dart",
				"rust",
				"typescript",
				"tsx",
				"javascript",
				"jsx"
			},
			auto_install = true,
			highlight = {
				enable = true
			},
			indent = {
				enable = true,
				disable = {}
			}
		}
	}
}
