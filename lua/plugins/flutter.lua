return {
	{
		"nvim-flutter/flutter-tools.nvim",
		ft = "dart",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"saghen/blink.cmp", -- Ensure blink is a dependency
		},
		config = function()

			local capabilities = require('blink.cmp').get_lsp_capabilities()

			require("flutter-tools").setup({
				dev_log = {
					enabled = false,
					open_cmd = "tabedit"
				},
				lsp = {
					capabilities = capabilities,
					color_capabilities = true,
					settings = {
						showTodos = true,
						completeFunctionCalls = true,
						closingLabels = true,
						displayInlayHints = false,
						lineLength = 120
					},
				},
			})
		end,
	},
}
