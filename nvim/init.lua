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
})

--------------------------------------------------
-- LSP
--------------------------------------------------
vim.lsp.config("clangd", {
    cmd = { "clangd" },
    filetypes = { "c", "cpp" },
})
vim.lsp.enable("clangd")

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
