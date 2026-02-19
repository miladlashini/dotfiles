return function(on_attach, capabilities)
    vim.lsp.config("pyright", {
        on_attach = on_attach,
        capabilities = capabilities,
    })

    vim.lsp.enable("pyright")
end
