local capabilities = require("cmp_nvim_lsp").default_capabilities()
-- Mason setup
config = function()
    require("mason").setup()

    require("mason-lspconfig").setup({
        ensure_installed = { "clangd", "neocmake", "pyright", "bashls" },
    })

    local lspconfig = require("lspconfig")

    --------------------------------------------------
    -- LSP Keymaps
    --------------------------------------------------
    local on_attach = function(_, bufnr)
        local opts = { buffer = bufnr }
        --     -- <C-o>   → jump back
        --     -- <C-i>   → jump forward
        vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
        vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
        vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
        vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
        vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
    end

    --------------------------------------------------
    -- Load individual servers
    --------------------------------------------------
    require("config.lsp.clangd")(lspconfig, on_attach)
    require("config.lsp.neocmake")(lspconfig, on_attach)
    require("config.lsp.pyright")(lspconfig, on_attach)
    require("config.lsp.bashls")(lspconfig, on_attach)

end
