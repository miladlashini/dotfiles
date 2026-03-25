require("nvim-tree").setup({
    view = {
        width = 30,
        side = "left",
    },
    renderer = {
        highlight_git = true,
        icons = {
            show = {
                git = true,
            },
        },
    },
    git = {
        enable = true,
    },
   filters = {
        dotfiles = false,
    },
   git = {
        ignore = false,
    },
})

-- Optional keymap
vim.keymap.set("n", "<leader>e", ":NvimTreeToggle<CR>", { desc = "Toggle file tree" })
