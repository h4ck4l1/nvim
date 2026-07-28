return {
	{
		"mrcjkb/rustaceanvim",
		ft = { "rust" },
		init = function ()
			vim.g.rustaceanvim = {
				server = {
					on_attach = function (client, bufnr)
						client.server_capabilities.semanticTokensProvider = nil
					end,
					extraEnv = {
						CARGO_TARGET_DIR = "target/rust-analyzer",
						CARGO_BUILD_JOBS = "2"
					},
					settings = {
						['rust-analyzer'] = {
							cachePriming = { enable = false },
							procMacro = {
								enable = true,
								ignored = {
									["napi-derive"] = { "napi" },
								},
							},
							inlayHints = {
								chainingHints = { enable = false },
								typeHints = { enable = true },
								parameterHints = { enable = true },
								renderColons = true
							},
							completion = {
								callable = { snippets = "add_parentheses" },
                                fullFunctionSignatures = { enable = false },
                                autoimport = { enable = true },
								postfix = { enable = false },
							},
							imports = {
								granularity = { group = "module" },
								prefix = "self"
							},
							diagnostics = {
								enable = true,
								disabled = { "unresolved-proc-macro" },
							},
							cargo = {
								allFeatures = true,
								loadOutDirsFromCheck = true,
								buildScripts = { enable = true },
							},
							checkOnSave = {
								command = "clippy",
								extraArgs = { "--no-deps" },
							},
							files = {
								excludeDirs = {
									".dart_tool",
									".flutter-plugins",
									".flutter-plugins-dependencies",
									"build",
									"target",
									"node_modules",
									".git"
								}
							}
						},
					},
				},
			}
		end
	},
	{
		"statiolake/rust-import.nvim",
		ft = "rust",
		dependencies = { "mrcjkb/rustaceanvim" },
		config = function()
			require("rust-import").setup()
		end,
		keys = {
			{
				"<leader>cb",
				"<cmd>RustOrganizeImports<cr>",
				desc = "Source Action (Clean & Organize Imports)"
			}
		}
	}
}
