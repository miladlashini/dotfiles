require("conform").setup({
    formatters_by_ft = {
        cpp = { "clang-format" },
        c   = { "clang-format" },
    },

    format_on_save = {
        timeout_ms = 500,
        lsp_format = "fallback",
    },
})
