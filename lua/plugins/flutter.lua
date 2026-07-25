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
				default_run_args = {
					"--dart-define-from-file=env.dev.json"
				},
				dev_log = {
					enabled = true,
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
