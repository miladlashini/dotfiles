require("gitsigns").setup({
    current_line_blame_opts = {
        virt_text = true,
        virt_text_pos = "eol",
        delay = 200,
    }
    -- You can add more options here if needed
    -- e.g., signs = { add = '+', change = '~', delete = '_' },
})
