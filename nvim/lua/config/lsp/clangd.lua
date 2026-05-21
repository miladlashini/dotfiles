return function(on_attach, capabilities)
    vim.lsp.config("clangd", {
        on_attach = on_attach,
        capabilities = capabilities,
        cmd = { vim.fn.expand("~/.local/share/nvim/mason/bin/clangd"), 
        "--background-index", 
        "--background-index-priority=normal",
        "--clang-tidy",  
        "--header-insertion=iwyu", 
        "--completion-style=detailed",
        "--fallback-style=llvm",
        "--pch-storage=memory",
        "--cross-file-rename",
        "--suggest-missing-includes",
        "--all-scopes-completion", 
    },    
        filetypes = { "c", "cpp" },
    })

    vim.lsp.enable("clangd")
end                                                                                                                                                                                                               
