require("conform").setup({
    formatters_by_ft = {
        cpp = { "clang-format-19" },
        c   = { "clang-format-19" },
    },

    format_on_save = {
        timeout_ms = 500,
        lsp_format = "fallback",
    },
})
