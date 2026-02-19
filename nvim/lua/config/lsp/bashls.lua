return function(on_attach, capabilities)
        vim.lsp.config("bashls", {                                                                                                                                                                                                                     
            capabilities = capabilities,                                                                                                                                                                                                               
            on_attach = on_attach,                                                                                                                                                                                                                     
        })                                                                                                                                                                                                                                             
        vim.lsp.enable("bashls")
end
