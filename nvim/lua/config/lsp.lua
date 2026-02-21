local M = {}

function M.setup()
    require("mason").setup()

    require("mason-lspconfig").setup({
        ensure_installed = { "clangd", "neocmake", "pyright", "bashls", "jsonls", "systemd_lsp" },
    })

    -- 🔥 Required for "blink.cmp"
    local capabilities = require("blink.cmp").get_lsp_capabilities()

    --------------------------------------------------
    -- Keymaps when LSP attaches
    --------------------------------------------------
    local on_attach = function(_, bufnr)
        local opts = { buffer = bufnr }

        vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
        vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
        vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
        vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
        vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
    end

    --------------------------------------------------
    -- Load individual servers
    --------------------------------------------------
    require("config.lsp.clangd")(on_attach, capabilities)
    require("config.lsp.neocmake")(on_attach, capabilities)
    require("config.lsp.pyright")(on_attach, capabilities)
    require("config.lsp.bashls")(on_attach, capabilities)
    require("config.lsp.jsonls")(on_attach, capabilities)
    require("config.lsp.systemd_lsp")(on_attach, capabilities)
end

return M
