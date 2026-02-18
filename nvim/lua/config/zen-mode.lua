require("zen-mode").setup({
    window = {
        backdrop = 0,  -- shade the rest of the editor
        width = 120,   -- width of the central window
        height = 1,    -- height multiplier (1 = full height)
    },
    plugins = {
        -- optional: hide statusline, line numbers, etc
        options = {
            showcmd = true,
            ruler = true,
        },
    },
})

vim.keymap.set("n", "<leader>z", function()
    require("zen-mode").toggle()
end, { desc = "Toggle Zoom" })