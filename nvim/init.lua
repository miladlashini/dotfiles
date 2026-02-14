vim.g.mapleader = " "

vim.g.tmux_navigator_no_mappings = 1

--------------------------------------------------
-- Split creation
--------------------------------------------------

-- Vertical split
vim.keymap.set("n", "<leader>v", ":vsplit<CR>", { desc = "Vertical split" })

-- Horizontal split
vim.keymap.set("n", "<leader>h", ":split<CR>", { desc = "Horizontal split" })

-- Close current split
vim.keymap.set("n", "<leader>q", ":close<CR>", { desc = "Close split" })



--vim.keymap.set("n", "<C-Left>",  "<cmd>TmuxNavigateLeft<CR>")
--vim.keymap.set("n", "<C-Right>", "<cmd>TmuxNavigateRight<CR>")
--vim.keymap.set("n", "<C-Up>",    "<cmd>TmuxNavigateUp<CR>")
--vim.keymap.set("n", "<C-Down>",  "<cmd>TmuxNavigateDown<CR>")

vim.keymap.set("n", "<C-Left>",  "<cmd>TmuxNavigateLeft<CR>",  { silent = true })
vim.keymap.set("n", "<C-Right>", "<cmd>TmuxNavigateRight<CR>", { silent = true })
vim.keymap.set("n", "<C-Up>",    "<cmd>TmuxNavigateUp<CR>",    { silent = true })
vim.keymap.set("n", "<C-Down>",  "<cmd>TmuxNavigateDown<CR>",  { silent = true })


--------------------------------------------------
-- Resize splits using Alt + Arrow
--------------------------------------------------

vim.keymap.set("n", "<M-Left>",  ":vertical resize -3<CR>")
vim.keymap.set("n", "<M-Right>", ":vertical resize +3<CR>")
vim.keymap.set("n", "<M-Up>",    ":resize +2<CR>")
vim.keymap.set("n", "<M-Down>",  ":resize -2<CR>")


-- Open vertical splits to the right
vim.opt.splitright = true

-- Open horizontal splits below
vim.opt.splitbelow = true


--------------------------------------------------
-- Basics (mouse & arrows friendly)
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

--------------------------------------------------
-- Faster startup
--------------------------------------------------
vim.loader.enable()

--------------------------------------------------
-- Colors (simple & fast)
--------------------------------------------------
vim.cmd.colorscheme("default")
vim.api.nvim_set_hl(0, "CursorLine", { bg = "#1c1c1c" })
vim.api.nvim_set_hl(0, "Visual", { bg = "#264f78" })

--------------------------------------------------
-- lazy.nvim bootstrap
--------------------------------------------------
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({

    --------------------------------------------------
    -- Gruvbox Colorscheme
    --------------------------------------------------
    {
    "ellisonleao/gruvbox.nvim",
    priority = 1000, -- load before other plugins
    config = function()
        require("gruvbox").setup({
        contrast = "hard",  -- soft | medium | hard
        transparent_mode = false,
        })
        vim.cmd.colorscheme("gruvbox")
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
                view = { width = 30 },
                renderer = { highlight_git = true },
            })
        end,
    },

    --------------------------------------------------
    -- Status line (pretty but light)
    --------------------------------------------------
    {
        "nvim-lualine/lualine.nvim",
        config = function()
            require("lualine").setup({
                options = {
                    theme = "auto",
                    section_separators = "",
                    component_separators = "",
                },
            })
        end,
    },

    --------------------------------------------------
    -- Fuzzy finder
    --------------------------------------------------
    {
        "ibhagwan/fzf-lua",
        config = function()
            require("fzf-lua").setup({
                winopts = { preview = { layout = "vertical" } },
            })
        end,
    },

    --------------------------------------------------
    -- Autocomplete (arrow-key friendly)
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
    -- tmux <-> vim
    --------------------------------------------------
    {
    "christoomey/vim-tmux-navigator",
    },

    --------------------------------------------------
    -- True Zoom Mode (like tmux prefix+z)
    --------------------------------------------------
    {
    "folke/zen-mode.nvim",
    opts = {
        window = {
        backdrop = 1,
        width = 120,      -- full width
        height = 1,     -- full height
        options = {
            number = true,
            relativenumber = false,
        },
        },
    },
    },

})

--------------------------------------------------
-- Built-in LSP (Neovim 0.11+)
--------------------------------------------------
vim.lsp.config("clangd", {
    cmd = { "clangd" },
    filetypes = { "c", "cpp", "objc", "objcpp" },
})

vim.lsp.enable("clangd")

--------------------------------------------------
-- Mouse-based LSP navigation
--------------------------------------------------
vim.keymap.set("n", "<RightMouse>", vim.lsp.buf.definition)
vim.keymap.set("n", "<LeftMouse>", "<LeftMouse>")

--------------------------------------------------
-- FZF keybindings
--------------------------------------------------


-- Search files space + f
vim.keymap.set("n", "<leader>f", function()
  require("fzf-lua").files()
end, { desc = "Find files" })

-- Search text (ripgrep) space + g
vim.keymap.set("n", "<leader>g", function()
  require("fzf-lua").live_grep()
end, { desc = "Live grep" })


--------------------------------------------------
-- Auto-open tree when starting Neovim in a directory
--------------------------------------------------
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function(data)
    local dir = data.file
    if vim.fn.isdirectory(dir) == 1 then
      vim.cmd.cd(dir)
      require("nvim-tree.api").tree.open()
    end
  end,
})

--------------------------------------------------
-- Space + z → Toggle Zoom
--------------------------------------------------

vim.keymap.set("n", "<leader>z", function()
  require("zen-mode").toggle()
end, { desc = "Toggle Zoom" })




