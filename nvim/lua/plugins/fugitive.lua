return {
  "tpope/vim-fugitive",
  cmd = {
    "Git",
    "G",
    "Gdiffsplit",
    "Gvdiffsplit",
    "Gwrite",
    "Gread",
    "Ggrep",
    "GMove",
    "GDelete",
    "GBrowse",
  },
  keys = {
    { "<leader>gs", "<cmd>Git<CR>", desc = "Git Status" },
    { "<leader>gc", "<cmd>Git commit<CR>", desc = "Git Commit" },
    { "<leader>gp", "<cmd>Git push<CR>", desc = "Git Push" },
    { "<leader>gl", "<cmd>Git pull<CR>", desc = "Git Pull" },
    { "<leader>gb", "<cmd>Git blame<CR>", desc = "Git Blame" },
  },
}
