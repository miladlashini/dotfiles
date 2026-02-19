return function(lspconfig, on_attach)
    lspconfig.bashls.setup({
       -- capabilities = capabilities,
        on_attach = on_attach,
    })
end
