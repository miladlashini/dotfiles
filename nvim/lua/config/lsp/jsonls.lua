return function(on_attach, capabilities)
    vim.lsp.config("jsonls", {
        on_attach = on_attach,
        capabilities = capabilities,
    })

    vim.lsp.enable("jsonls")
end