local cmp = require("cmp")

cmp.setup({
    mapping = {
        ["<Down>"] = cmp.mapping.select_next_item(),
        ["<Up>"]   = cmp.mapping.select_prev_item(),
        ["<CR>"]   = cmp.mapping.confirm({ select = true }),
    },
    sources = {
        { name = "nvim_lsp" },
        { name = "buffer" },
        { name = "path" },
    },
})
