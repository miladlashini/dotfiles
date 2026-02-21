return function(on_attach, capabilities)
    vim.lsp.config("clangd", {
        on_attach = on_attach,
        capabilities = capabilities,
        cmd = { "clangd", 
        "--background-index", 
        "--clang-tidy",  
        "--header-insertion=iwyu", 
        "--completion-style=detailed",
        "--fallback-style=llvm",
        "--pch-storage=memory",
        "--cross-file-rename",
        "--suggest-missing-includes",
        "--all-scopes-completion" },
        
        filetypes = { "c", "cpp" },
    })

    vim.lsp.enable("clangd")
end                                                                                                                                                                                                               
