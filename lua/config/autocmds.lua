-- vim.api.nvim_create_autocmd(
-- 	{ "FocusGained", "BufEnter", "CursorHold" },
-- 	{
-- 		callback = function ()
-- 			if vim.fn.getcmdwintype() == "" then
-- 				vim.cmd("checktime")
-- 			end
-- 		end
-- 	}
-- )

-- Auto reload files when changed on disk (e.g. from another Neovim instance)
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold" }, {
  command = "if mode() != 'c' | checktime | endif",
  pattern = "*",
})

-- Strict read-only mode: only lock actual source code files, ignore UI/explorer buffers
if vim.env.READONLY_MODE == "1" then
  vim.api.nvim_create_autocmd("BufReadPost", {
    callback = function(ev)
      -- buftype == "" ensures we only lock real files, not UI/scratch buffers
      if vim.bo[ev.buf].buftype == "" then
        vim.bo[ev.buf].modifiable = false
        vim.bo[ev.buf].readonly = true
      end
    end,
  })
end

vim.api.nvim_create_autocmd("FileType", {
    pattern = "dart",
    callback = function()
        vim.opt_local.tabstop = 2      -- Render actual tabs as 4 spaces
        vim.opt_local.shiftwidth = 2   -- Use 4 spaces for auto-indentation
        vim.opt_local.softtabstop = 2
        vim.opt_local.expandtab = true  -- Pressing Tab inserts spaces
    end,
})



vim.filetype.add({
	extension = {
		frag = "glsl",
		vert = "glsl",
		comp = "glsl"
	}
})


local view_group = vim.api.nvim_create_augroup("PersistentFolds", { clear = true })

-- Save the view (folds, cursor position, etc.) when leaving a buffer or window
vim.api.nvim_create_autocmd({ "BufWinLeave", "BufWritePost", "WinLeave" }, {
  group = view_group,
  desc = "Save view with mkview for real files",
  callback = function(args)
    if vim.b[args.buf].view_activated then
      vim.cmd.mkview({ mods = { emsg_silent = true } })
    end
  end,
})

-- Load the view when opening a buffer
vim.api.nvim_create_autocmd("BufWinEnter", {
  group = view_group,
  desc = "Load view with loadview for real files",
  callback = function(args)
    if not vim.b[args.buf].view_activated then
      local filetype = vim.api.nvim_get_option_value("filetype", { buf = args.buf })
      local buftype = vim.api.nvim_get_option_value("buftype", { buf = args.buf })
      local ignore_filetypes = { "gitcommit", "gitrebase" }

      -- Ensure we only do this for standard files (not Neo-tree, Telescope, etc.)
      if buftype == "" and filetype and filetype ~= "" and not vim.tbl_contains(ignore_filetypes, filetype) then
        vim.b[args.buf].view_activated = true
        vim.cmd.loadview({ mods = { emsg_silent = true } })
      end
    end
  end,
})


-- local float_win = nil
-- local float_buf = nil
-- local home_pos = nil
-- local current_side = nil 
-- local pin_enabled = true -- Global toggle state
--
-- local function close_float()
--     if float_win and vim.api.nvim_win_is_valid(float_win) then
--         vim.api.nvim_win_close(float_win, true)
--     end
--     float_win = nil
--     float_buf = nil
--     current_side = nil
-- end
--
-- local function update_float(bufnr, lnum, side)
--     -- If already open on the correct side, short-circuit
--     if current_side == side and float_win and vim.api.nvim_win_is_valid(float_win) then
--         return
--     end
--
--     local current_win = vim.api.nvim_get_current_win()
--     if vim.api.nvim_win_get_config(current_win).relative ~= "" then return end
--
--     local win_width = vim.api.nvim_win_get_width(current_win)
--     local win_height = vim.api.nvim_win_get_height(current_win)
--     local line_text = vim.api.nvim_buf_get_lines(bufnr, lnum - 1, lnum, false)[1] or ""
--
--     -- Calculate a tight, compact width based on content length
--     local text_len = vim.fn.strdisplaywidth(line_text)
--     local title_text = string.format(" 📍 Line %d ", lnum)
--     local title_len = vim.fn.strdisplaywidth(title_text)
--
--     local float_width = math.max(text_len, title_len) + 4
--     float_width = math.min(float_width, math.floor(win_width * 0.5)) -- Cap at 50% screen max
--     if float_width < 22 then float_width = 22 end
--
--     -- Move columns to the far right side of the window
--     local col_pos = win_width - float_width - 4
--
--     if not float_buf or not vim.api.nvim_buf_is_valid(float_buf) then
--         float_buf = vim.api.nvim_create_buf(false, true)
--     end
--     vim.api.nvim_buf_set_lines(float_buf, 0, -1, false, { line_text })
--     vim.bo[float_buf].filetype = vim.bo[bufnr].filetype
--
--     local row_pos = (side == "top") and 0 or math.max(0, win_height - 4)
--
--     local opts = {
--         relative = "win",
--         win = current_win,
--         row = row_pos,
--         col = col_pos, -- Docked right side
--         width = float_width,
--         height = 1,
--         style = "minimal",
--         border = "rounded",
--         title = { { title_text, "DiagnosticInfo" } },
--         title_pos = "right", -- Clean right alignment
--         focusable = false,
--         zindex = 45,
--     }
--
--     if float_win and vim.api.nvim_win_is_valid(float_win) then
--         vim.api.nvim_win_set_config(float_win, opts)
--     else
--         float_win = vim.api.nvim_open_win(float_buf, false, opts)
--         vim.api.nvim_set_option_value("winhl", "Normal:NormalFloat,Border:FloatBorder", { win = float_win })
--     end
--
--     current_side = side 
-- end
--
-- -- Core monitoring loop
-- vim.api.nvim_create_autocmd({ "CursorMoved", "WinScrolled", "BufLeave" }, {
--     group = vim.api.nvim_create_augroup("ScrollHoverPin", { clear = true }),
--     callback = function(ev)
--         -- Master Switch Guard
--         if not pin_enabled then
--             close_float()
--             return
--         end
--
--         local bufnr = vim.api.nvim_get_current_buf()
--         if vim.bo[bufnr].buftype ~= "" then
--             close_float()
--             return
--         end
--
--         if ev.event == "BufLeave" then
--             close_float()
--             home_pos = nil
--             return
--         end
--
--         local current_win = vim.api.nvim_get_current_win()
--         local cursor_lnum = vim.api.nvim_win_get_cursor(current_win)[1]
--
--         if not home_pos or home_pos.bufnr ~= bufnr then
--             home_pos = { bufnr = bufnr, lnum = cursor_lnum }
--         end
--
--         local mode = vim.api.nvim_get_mode().mode
--         if mode == "i" or mode == "R" or mode == "v" or mode == "V" or mode == "\22" then
--             if mode == "i" or mode == "R" then
--                 home_pos.lnum = cursor_lnum
--             end
--             close_float() 
--             return
--         end
--
--         local w0 = vim.fn.line("w0")
--         local w1 = vim.fn.line("w1")
--
--         if home_pos.lnum < w0 then
--             update_float(home_pos.bufnr, home_pos.lnum, "top")
--         elseif home_pos.lnum > w1 then
--             update_float(home_pos.bufnr, home_pos.lnum, "bottom")
--         else
--             close_float()
--         end
--     end,
-- })
--
-- -- Reset anchor on edits
-- vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "InsertLeave" }, {
--     group = vim.api.nvim_create_augroup("ScrollHoverPinReset", { clear = true }),
--     callback = function()
--         local bufnr = vim.api.nvim_get_current_buf()
--         if vim.bo[bufnr].buftype == "" then
--             local current_win = vim.api.nvim_get_current_win()
--             local cursor_lnum = vim.api.nvim_win_get_cursor(current_win)[1]
--             home_pos = { bufnr = bufnr, lnum = cursor_lnum }
--             close_float()
--         end
--     end,
-- })
--
-- -- KEYMAP 1: Toggle the Pin On/Off entirely
-- vim.keymap.set("n", "<leader>uH", function()
--     pin_enabled = not pin_enabled
--     if pin_enabled then
--         vim.notify("Hover Pin Enabled", vim.log.levels.INFO, { title = "UI" })
--     else
--         close_float()
--         vim.notify("Hover Pin Disabled", vim.log.levels.WARN, { title = "UI" })
--     end
-- end, { desc = "Toggle Hover Pin Overlay" })
--
-- -- KEYMAP 2: Manual reset anchor to current line
-- vim.keymap.set("n", "<leader>hp", function()
--     if not pin_enabled then return end
--     local bufnr = vim.api.nvim_get_current_buf()
--     local current_win = vim.api.nvim_get_current_win()
--     local cursor_lnum = vim.api.nvim_win_get_cursor(current_win)[1]
--     home_pos = { bufnr = bufnr, lnum = cursor_lnum }
--     close_float()
-- end, { desc = "Reset Hover Pin Anchor" })
--
--
