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
        vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
        vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
        vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
        vim.keymap.set("n", "<leader>rn", function()
            local params = vim.lsp.util.make_position_params(0, "utf-8")
            local new_name = vim.fn.input("New name: ")
            if new_name == "" then return end

            vim.lsp.buf_request(0, "textDocument/rename",
                vim.tbl_extend("force", params, { newName = new_name }),
                function(err, result)
                if err or not result then return end
                vim.lsp.util.apply_workspace_edit(result, "utf-8")
                -- Save all modified buffers
                for _, buf in ipairs(vim.api.nvim_list_bufs()) do
                    if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].modified then
                    vim.api.nvim_buf_call(buf, function()
                        vim.cmd("write")
                    end)
                    end
                end
                end
            )
            end, opts)
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
