return function(on_attach, capabilities)
    vim.lsp.config("rust_analyzer", {
        on_attach = on_attach,
        capabilities = capabilities,
    })

    vim.lsp.enable("rust_analyzer")
end
