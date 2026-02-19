return function(lspconfig, on_attach)
    lspconfig.neocmake.setup({
        --capabilities = capabilities,
        on_attach = on_attach,
        filetypes = { "cmake" },
        root_dir = lspconfig.util.root_pattern("CMakeLists.txt", ".git"),
    })
end
