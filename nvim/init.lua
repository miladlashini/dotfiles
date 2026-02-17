--------------------------------------------------
-- LEADER
--------------------------------------------------
vim.g.mapleader = " "
vim.g.tmux_navigator_no_mappings = 1

--------------------------------------------------
-- BASIC SETTINGS
--------------------------------------------------
vim.opt.number = true
vim.opt.relativenumber = false
vim.opt.mouse = "a"
vim.opt.clipboard = "unnamedplus"
vim.opt.termguicolors = true
vim.opt.signcolumn = "yes"
vim.opt.cursorline = true
vim.opt.scrolloff = 5
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.o.background = "dark"

vim.loader.enable()

--------------------------------------------------
-- KEYMAPS
--------------------------------------------------

-- Splits
vim.keymap.set("n", "<leader>v", "<cmd>vsplit<CR>", { desc = "Vertical split" })
vim.keymap.set("n", "<leader>h", "<cmd>split<CR>",  { desc = "Horizontal split" })
vim.keymap.set("n", "<leader>q", "<cmd>close<CR>",  { desc = "Close split" })

-- Tmux navigation
vim.keymap.set("n", "<C-Left>",  "<cmd>TmuxNavigateLeft<CR>",  { silent = true })
vim.keymap.set("n", "<C-Right>", "<cmd>TmuxNavigateRight<CR>", { silent = true })
vim.keymap.set("n", "<C-Up>",    "<cmd>TmuxNavigateUp<CR>",    { silent = true })
vim.keymap.set("n", "<C-Down>",  "<cmd>TmuxNavigateDown<CR>",  { silent = true })

-- Resize
vim.keymap.set("n", "<M-Left>",  "<cmd>vertical resize -3<CR>")
vim.keymap.set("n", "<M-Right>", "<cmd>vertical resize +3<CR>")
vim.keymap.set("n", "<M-Up>",    "<cmd>resize +2<CR>")
vim.keymap.set("n", "<M-Down>",  "<cmd>resize -2<CR>")

-- File explorer
vim.keymap.set("n", "<leader>t", "<cmd>NvimTreeToggle<CR>", { desc = "Toggle File Explorer" })

-- Tab navigation
vim.keymap.set("n", "<leader>n", ":tabnext<CR>")

--------------------------------------------------
-- lazy.nvim
--------------------------------------------------
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
vim.opt.rtp:prepend(lazypath)

--------------------------------------------------
-- PLUGINS
--------------------------------------------------

require("lazy").setup({
    --------------------------------------------------
    -- Colorscheme
    --------------------------------------------------
    {
        "ellisonleao/gruvbox.nvim",
        priority = 1000,
        config = function()
            require("gruvbox").setup({
                contrast = "medium",
            })
            vim.cmd.colorscheme("gruvbox")
        end,
    },

    --------------------------------------------------
    -- Telescope
    --------------------------------------------------
    {
    "nvim-telescope/telescope.nvim",
    dependencies = {
        "nvim-lua/plenary.nvim",
        {
            "nvim-telescope/telescope-fzf-native.nvim",
            build = "make"
        }
    },
    config = function()
        local telescope = require("telescope")
        telescope.setup({})
        telescope.load_extension("fzf")

        local builtin = require("telescope.builtin")
        vim.keymap.set("n", "<leader>f", builtin.find_files)
        vim.keymap.set("n", "<leader>g", builtin.live_grep)
        vim.keymap.set("n", "<leader>b", builtin.buffers)
        vim.keymap.set("n", "<leader>h", builtin.help_tags)
    end,
    },

    --------------------------------------------------
    -- File tree
    --------------------------------------------------
    {
        "nvim-tree/nvim-tree.lua",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        config = function()
            require("nvim-tree").setup({
                view = {
                    width = 30,
                    side = "left",
                },
                renderer = {
                    highlight_git = true,
                    icons = {
                        show = {
                            git = true,
                        },
                    },
                },
                git = {
                    enable = true,
                },
            })
        end,
    },

    --------------------------------------------------
    -- Status line
    --------------------------------------------------
    {
        "nvim-lualine/lualine.nvim",
        config = function()
            require("lualine").setup({
                options = { theme = "auto" },
            })
        end,
    },

    --------------------------------------------------
    -- Which Key
    --------------------------------------------------
    {
        "folke/which-key.nvim",
        config = function()
            require("which-key").setup()
        end,
    },


    --------------------------------------------------
    -- Store
    --------------------------------------------------
    {
    "alex-popov-tech/store.nvim",
    dependencies = { "OXY2DEV/markview.nvim" },
    opts = {},
    cmd = "Store"
    },

    --------------------------------------------------
    -- Mason + LSP
    --------------------------------------------------
    {
        "williamboman/mason.nvim",
        config = function()
            require("mason").setup()
        end,
    },

    {
    "neovim/nvim-lspconfig",
    dependencies = {
        "williamboman/mason.nvim",
        "williamboman/mason-lspconfig.nvim",
    },
    config = function()
        require("mason").setup()

        require("mason-lspconfig").setup({
        ensure_installed = { "clangd", "neocmake", "pyright", "bashls"},
        })


        -- LSP keymaps (applied when LSP attaches to buffer)
        local on_attach = function(_, bufnr)
        local opts = { buffer = bufnr }
        -- <C-o>   → jump back
        -- <C-i>   → jump forward

        vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
        vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
        vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
        vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
        vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
        end

        --------------------------------------------------
        -- C / C++
        --------------------------------------------------
        vim.lsp.config('clangd', {
            on_attach = on_attach,
            filetypes = { "c", "cpp" },
            cmd = { "clangd", "--background-index", "--clang-tidy",},
        })
        vim.lsp.enable('clangd')

        --------------------------------------------------
        -- CMake (neocmake)
        --------------------------------------------------
        vim.lsp.config("neocmake", {
            capabilities = capabilities,
            on_attach = on_attach,
            cmd = { "neocmake" },
            filetypes = { "cmake" },
            root_markers = { "CMakeLists.txt", ".git" },
        })

        vim.lsp.enable("neocmake")
        

        --------------------------------------------------
        -- Python
        --------------------------------------------------
        vim.lsp.config("pyright", {
            capabilities = capabilities,
            on_attach = on_attach,
        })
        vim.lsp.enable("pyright")

        --------------------------------------------------
        -- Bash
        --------------------------------------------------
        vim.lsp.config("bashls", {
            capabilities = capabilities,
            on_attach = on_attach,
        })
        vim.lsp.enable("bashls")
    end,
    },

    --------------------------------------------------
    -- Completion
    --------------------------------------------------
    {
        "hrsh7th/nvim-cmp",
        dependencies = {
            "hrsh7th/cmp-nvim-lsp",
            "hrsh7th/cmp-buffer",
            "hrsh7th/cmp-path",
        },
        config = function()
            local cmp = require("cmp")
            cmp.setup({
                mapping = {
                    ["<Down>"] = cmp.mapping.select_next_item(),
                    ["<Up>"]   = cmp.mapping.select_prev_item(),
                    ["<CR>"]   = cmp.mapping.confirm({ select = true }),
                },
                sources = {
                    { name = "nvim_lsp" },
                    { name = "buffer" },
                    { name = "path" },
                },
            })
        end,
    },

    --------------------------------------------------
    -- Formatting
    --------------------------------------------------
    {
        "stevearc/conform.nvim",
        config = function()
            require("conform").setup({
                formatters_by_ft = {
                    cpp = { "clang-format-19" },
                    c = { "clang-format-19" },
                },
                format_on_save = {
                    -- These options will be passed to conform.format()
                    timeout_ms = 500,
                    lsp_format = "fallback",
                },
            })
        end,
    },

    --------------------------------------------------
    -- Git
    --------------------------------------------------
    {
        "lewis6991/gitsigns.nvim",
        config = function()
            require("gitsigns").setup( {current_line_blame = true} )
        end,
    },

    --------------------------------------------------
    -- Tmux integration
    --------------------------------------------------
    { "christoomey/vim-tmux-navigator" },

    --------------------------------------------------
    -- Zoom
    --------------------------------------------------
    {
        "folke/zen-mode.nvim",
        opts = {
            window = {
                backdrop = 0,
                width = 120,
                height = 1,
            },
        },
    },
    --------------------------------------------------
    -- Dashboard
    --------------------------------------------------
    {
        "nvimdev/dashboard-nvim",
        event = "VimEnter",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        config = function()
            local dashboard = require("dashboard")

            dashboard.setup({
            theme = "hyper",
            config = {
                -- header = {
                -- " ███╗   ██╗██╗   ██╗██╗███╗   ███╗",
                -- " ████╗  ██║██║   ██║██║████╗ ████║",
                -- " ██╔██╗ ██║██║   ██║██║██╔████╔██║",
                -- " ██║╚██╗██║╚██╗ ██╔╝██║██║╚██╔╝██║",
                -- " ██║ ╚████║ ╚████╔╝ ██║██║ ╚═╝ ██║",
                -- " ╚═╝  ╚═══╝  ╚═══╝  ╚═╝╚═╝     ╚═╝",
                -- },

                header = {
                    "██╗   ██╗██╗███████╗███████╗██████╗ ██╗ ██████╗ ███╗   ██╗",
                    "██║   ██║██║██╔════╝██╔════╝██╔══██╗██║██╔═══██╗████╗  ██║",
                    "██║   ██║██║███████╗█████╗  ██████╔╝██║██║   ██║██╔██╗ ██║",
                    "╚██╗ ██╔╝██║╚════██║██╔══╝  ██╔══██╗██║██║   ██║██║╚██╗██║",
                    " ╚████╔╝ ██║███████║███████╗██║  ██║██║╚██████╔╝██║ ╚████║",
                    "  ╚═══╝  ╚═╝╚══════╝╚══════╝╚═╝  ╚═╝╚═╝ ╚═════╝ ╚═╝  ╚═══╝",
                },

                shortcut = {
                {
                    desc = "󰱼  Find File",
                    group = "@property",
                    action = "Telescope find_files",
                    key = "f",
                },
                {
                    desc = "󰈚  Recent Files",
                    group = "Label",
                    action = "Telescope oldfiles",
                    key = "r",
                },
                {
                    desc = "󰒲  Plugin Store",
                    group = "Number",
                    action = "Store",
                    key = "s",
                },
                {
                    desc = "  Update Plugins",
                    group = "DiagnosticHint",
                    action = "Lazy sync",
                    key = "u",
                },
                {
                    desc = "  Quit",
                    group = "Error",
                    action = "qa",
                    key = "q",
                },
                },

                footer = {
                "🚀",
                },
            },
            })
            vim.cmd([[
               highlight DashboardHeader guifg=#66FFFF
               ]])
        end,
    },

    --------------------------------------------------
    -- Tabby
    --------------------------------------------------
    {
    "nanozuki/tabby.nvim",
        config = function()
            local theme = {
            fill = 'TabLineFill',
            -- Also you can do this: fill = { fg='#f2e9de', bg='#907aa9', style='italic' }
            head = 'TabLine',
            current_tab = 'TabLineSel',
            tab = 'TabLine',
            win = 'TabLine',
            tail = 'TabLine',
            }
            require('tabby').setup({
            line = function(line)
                return {
                {
                    { '  ', hl = theme.head },
                    line.sep('', theme.head, theme.fill),
                },
                line.tabs().foreach(function(tab)
                    local hl = tab.is_current() and theme.current_tab or theme.tab
                    return {
                    line.sep('', hl, theme.fill),
                    tab.is_current() and '' or '󰆣',
                    tab.number(),
                    tab.name(),
                    tab.close_btn(''),
                    line.sep('', hl, theme.fill),
                    hl = hl,
                    margin = ' ',
                    }
                end),
                line.spacer(),
                line.wins_in_tab(line.api.get_current_tab()).foreach(function(win)
                    return {
                    line.sep('', theme.win, theme.fill),
                    win.is_current() and '' or '',
                    win.buf_name(),
                    line.sep('', theme.win, theme.fill),
                    hl = theme.win,
                    margin = ' ',
                    }
                end),
                {
                    line.sep('', theme.tail, theme.fill),
                    { '  ', hl = theme.tail },
                },
                hl = theme.fill,
                }
            end,
            -- option = {}, -- setup modules' option,
            })
        end,
    }

})

--------------------------------------------------
-- Telescope Keymaps
--------------------------------------------------
local builtin = require("telescope.builtin")

vim.keymap.set("n", "<leader>f", builtin.find_files, { desc = "Find files" })
vim.keymap.set("n", "<leader>g", builtin.live_grep,  { desc = "Live grep" })
vim.keymap.set("n", "<leader>b", builtin.buffers,    { desc = "Buffers" })
vim.keymap.set("n", "<leader>h", builtin.help_tags,  { desc = "Help tags" })

--------------------------------------------------
-- Zoom toggle
--------------------------------------------------
vim.keymap.set("n", "<leader>z", function()
    require("zen-mode").toggle()
end, { desc = "Toggle Zoom" })

--------------------------------------------------
-- UI polish
--------------------------------------------------
vim.api.nvim_set_hl(0, "SignColumn", { bg = "none" })
vim.api.nvim_set_hl(0, "EndOfBuffer", { fg = "#3c3836" })

vim.keymap.set("n", "<leader>ps", "<cmd>Store<cr>", { desc = "Open Plugin Store" })

--------------------------------------------------
-- Tab Navigation
--------------------------------------------------

-- New tab
vim.keymap.set('n', '<leader>tn', '<cmd>tabnew<CR>', { desc = 'New Tab' })

-- Close current tab
vim.keymap.set('n', '<leader>tc', '<cmd>tabclose<CR>', { desc = 'Close Tab' })

-- Next / Previous tab
vim.keymap.set('n', '<S-Left>', '<cmd>tabnext<CR>', { desc = 'Next Tab' })
vim.keymap.set('n', '<S-Right>', '<cmd>tabprevious<CR>', { desc = 'Previous Tab' })

-- Go to tab by number
for i = 1, 9 do
  vim.keymap.set('n', '<leader>' .. i, i .. 'gt', { desc = 'Go to Tab ' .. i })
end

-- Move tab left / right
vim.keymap.set('n', '<leader>tmh', '<cmd>-tabmove<CR>', { desc = 'Move Tab Left' })
vim.keymap.set('n', '<leader>tml', '<cmd>+tabmove<CR>', { desc = 'Move Tab Right' })

-- Close all tabs except current
vim.keymap.set('n', '<leader>to', '<cmd>tabonly<CR>', { desc = 'Close Other Tabs' })


