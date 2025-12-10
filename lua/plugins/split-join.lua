

return {
	"Wansmer/treesj",
	keys = { '<leader>m', '<leader>j', '<leader>s' },
	dependencies = {'nvim-treesitter/nvim-treesitter'},
	config = function ()
		require('treesj').setup({
			use_default_keymaps = true,
			cursor_behaviour = "hold",
			max_join_length = 120
		})
	end
}
