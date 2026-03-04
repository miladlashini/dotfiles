local _init = function()
  local wk_available, wk = pcall(require, 'which-key')
  if wk_available then
    wk.add({
      { "<leader>t", group = "terminal" },
    })
  end
end

local _config = function()
  require('toggleterm').setup({
    size = function(term)
      if term.direction == "horizontal" then
        return 15
      elseif term.direction == "vertical" then
        return vim.o.columns * 0.4
      end
    end,
  })
end
-- Attention : to get out of the terminal, press <C-\><C-n> in normal mode
-- to switch between windows, press <C-w> and then the direction key (h, j, k, l)
return {
  'akinsho/toggleterm.nvim',
  config = _config,
  version = "*",
  init = _init,
  keys = {
    {
      '<leader>th',
      function()
        local term = require('toggleterm.terminal').Terminal
        local htop = term:new({ cmd = 'htop', hidden = true })
        htop:toggle()
      end,
    },
    {
      '<leader>tt',
      function()
        local term = require('toggleterm.terminal').Terminal
        local shell = term:new({ hidden = false, direction = 'float' })
        shell:toggle()
      end,
    },
    {
        "<leader>tb",
        "<cmd>ToggleTerm<cr>",
        desc = "Toggle last terminal",
    },
    {
        '<Esc>',
        [[<C-\><C-n><C-w>w]],
        mode = 't',
        desc = "Exit terminal and move focus",
    },
  },
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
}