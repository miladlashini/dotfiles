return function(on_attach, capabilities)
    vim.lsp.config("clangd", {
        on_attach = on_attach,
        capabilities = capabilities,
        cmd = { "clangd", "--background-index", "--clang-tidy" },
        filetypes = { "c", "cpp" },
    })

    vim.lsp.enable("clangd")
end                                                                                                                                                                                                               
