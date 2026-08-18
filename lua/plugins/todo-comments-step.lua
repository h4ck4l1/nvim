return {
	{
		"folke/todo-comments.nvim",
		opts = {
			keywords = {
				STEP = {
					icon = "✦",
					color = "info",
					alt = { "step", "Step" }
				},
				DONE = {
					icon = "✔",
					color = "test",
					alt = { "Done", "done" }
				},
				PROG = {
					icon = "◐",
					color = "warning",
					alt = { "Prog", "prog", "WIP", "wip" },
				},
			search = {
				-- Allows todo-comments to dynamically swap in the keywords we request
				pattern = [[\b(KEYWORDS):]],
			},
		},
		keys = {
			-- 1. Standard search (<leader>st)
			-- This lists the default primary keywords. It will automatically match all of
			-- their alternates (e.g., BUG, FIXME, WARNING) while completely excluding STEP.
			{
				"<leader>st",
				function()
					local has_snacks, snacks = pcall(require, "snacks")
					if has_snacks then
						snacks.picker.todo_comments({
							keywords = {"TODO", "FIX", "HACK", "WARN", "PERF", "NOTE", "TEST", "DONE"},
						})
					else
						vim.cmd("TodoTelescope keywords=TODO,FIX,HACK,WARN,PERF,NOTE,TEST,DONE")
					end
				end,
				desc = "Todo (excluding STEP)",
			},

			-- 2. Find only STEP comments in the current file (<leader>sf)
			{
				"<leader>sf",
				function()
					local current_file = vim.api.nvim_buf_get_name(0)
					if current_file == "" then
						vim.notify("No active file in the current buffer", vim.log.levels.WARN)
						return
					end

					local has_snacks, snacks = pcall(require, "snacks")
					if has_snacks then
						-- Searching for the primary keyword "STEP" automatically matches "step" and "Step"
						snacks.picker.todo_comments({
							keywords = {
								"STEP",
								"step",
								"Step"
							},
							dirs = { current_file },
						})
					else
						local has_telescope, telescope = pcall(require, "telescope")
						if has_telescope then
							telescope.extensions["todo-comments"].todo({
								keywords = "STEP",
								search_dirs = { current_file },
							})
						else
							vim.cmd("TodoLocList keywords=STEP")
						end
					end
				end,
				desc = "Find STEP comments in current file",
			},

			-- 3. Find only STEP comments in the CWD (<leader>sF)
			{
				"<leader>sF",
				function()
					local cwd = vim.fn.getcwd()

					local has_snacks, snacks = pcall(require, "snacks")
					if has_snacks then
						snacks.picker.todo_comments({
							keywords = {
								"STEP",
								"step",
								"Step"
							},
							dirs = { cwd },
						})
					else
						local has_telescope, telescope = pcall(require, "telescope")
						if has_telescope then
							telescope.extensions["todo-comments"].todo({
								keywords = "STEP",
								cwd = cwd,
							})
						else
							vim.cmd("TodoQuickFix keywords=STEP")
						end
					end
				end,
				desc = "Find STEP comments in CWD",
			},
		},
	},
}
