return function(lspconfig, on_attach)
    lspconfig.clangd.setup({
        capabilities = capabilities,
        on_attach = on_attach,
        cmd = { "clangd", "--background-index", "--clang-tidy" },
        filetypes = { "c", "cpp" },
    })
end
