  require("toggleterm").setup({
      size = 20,
      open_mapping = [[<c-\>]],
      hide_numbers = true,
      shade_filetypes = {},
      shade_terminals = true,
      shading_factor = 2,
      start_in_insert = true,
      insert_mappings = true,
      persist_size = true,
      direction = "float",
      close_on_exit = true,
      shell = vim.o.shell,
      float_opts = {
        border = "rounded",
        winblend = 0,
        highlights = {
          border = "Normal",
          background = "Normal",
        },
      },
    })
    -- Toggle terminal with C
  vim.keymap.set("n", "<leader>tt", "<cmd>ToggleTerm<CR>")
  -- Exit terminal mode with Esc (get out of focus) 
  -- close terminal with <leader>tt or <C-\>
  vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]])
   vim.keymap.set("n", "<leader>tf", 
   -- Focus the floating terminal if it exists, otherwise open a new one <leader>tf
   function()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
        local buf = vim.api.nvim_win_get_buf(win)
        if vim.bo[buf].buftype == "terminal" then
        vim.api.nvim_set_current_win(win)
        vim.cmd("startinsert")
        return
        end
    end
   end, { desc = "Focus floating terminal" })