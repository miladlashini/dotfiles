return function(lspconfig, on_attach)
    lspconfig.pyright.setup({
       -- capabilities = capabilities,
        on_attach = on_attach,
    })
end
