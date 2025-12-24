return {
	{
		"snacks.nvim",
		opts = {
			picker = {
				sources = {
					explorer = {
						layout = {
							preview = true, -- enable preview
							layout = {
								box = "horizontal",
								width = 0.8,
								height = 0.8,
								-- left column (input + list)
								{
									box = "vertical",
									border = "rounded",
									title = "{source} {live} {flags}",
									title_pos = "center",
									{ win = "input", height = 1, border = "bottom" },
									{ win = "list", border = "none" },
								},
								-- right column (preview)
								{
									win = "preview",
									border = "rounded",
									width = 0.7,
									title = "{preview}",
								},
							},
						},
						-- optional: keybinding you can also define here or in a separate snacks file
						keys = {
							{
								"<leader>e",
								function() require("snacks").explorer() end,
								desc = "Snacks: Explorer",
							},
						},
					},
				},
			},
		},
	},
}
