-- Splits
vim.keymap.set("n", "<leader>v", "<cmd>vsplit<CR>", { desc = "Vertical split" })
vim.keymap.set("n", "<leader>h", "<cmd>split<CR>",  { desc = "Horizontal split" })
vim.keymap.set("n", "<leader>q", "<cmd>close<CR>",  { desc = "Close split" })

-- Tmux navigation
vim.keymap.set("n", "<C-Left>",  "<cmd>TmuxNavigateLeft<CR>",  { silent = true })
vim.keymap.set("n", "<C-Right>", "<cmd>TmuxNavigateRight<CR>", { silent = true })
vim.keymap.set("n", "<C-Up>",    "<cmd>TmuxNavigateUp<CR>",    { silent = true })
vim.keymap.set("n", "<C-Down>",  "<cmd>TmuxNavigateDown<CR>",  { silent = true })

-- Resize splits
vim.keymap.set("n", "<M-Left>",  "<cmd>vertical resize -3<CR>")
vim.keymap.set("n", "<M-Right>", "<cmd>vertical resize +3<CR>")
vim.keymap.set("n", "<M-Up>",    "<cmd>resize +2<CR>")
vim.keymap.set("n", "<M-Down>",  "<cmd>resize -2<CR>")

-- File explorer
vim.keymap.set("n", "<leader>t", "<cmd>NvimTreeToggle<CR>", { desc = "Toggle File Explorer" })

-- Tab navigation
vim.keymap.set("n", "<leader>n", ":tabnext<CR>")
