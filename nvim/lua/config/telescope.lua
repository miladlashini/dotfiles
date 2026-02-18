local telescope = require("telescope")

telescope.setup({})
telescope.load_extension("fzf")

--------------------------------------------------
-- Telescope Keymaps
--------------------------------------------------

local builtin = require("telescope.builtin")

vim.keymap.set("n", "<leader>f", builtin.find_files, { desc = "Find files" })
vim.keymap.set("n", "<leader>g", builtin.live_grep,  { desc = "Live grep" })
vim.keymap.set("n", "<leader>b", builtin.buffers,    { desc = "Buffers" })
vim.keymap.set("n", "<leader>h", builtin.help_tags,  { desc = "Help tags" })
