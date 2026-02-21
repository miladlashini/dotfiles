return function(on_attach, capabilities)
    vim.lsp.config("systemd_lsp", {
        on_attach = on_attach,
        capabilities = capabilities,
    })

    vim.lsp.enable("systemd_lsp")
end