return function(on_attach, capabilities)
    vim.lsp.config("neocmakelsp", {
        cmd = { "neocmakelsp", "stdio" },
        filetypes = { "cmake" },
        root_markers = { "CMakeLists.txt", ".git" },
        capabilities = capabilities,
        on_attach = on_attach,
    })

    vim.lsp.enable("neocmakelsp")
end

