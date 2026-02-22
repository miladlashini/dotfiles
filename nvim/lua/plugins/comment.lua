-- lua/plugins/comment.lua
return {
    "numToStr/Comment.nvim",
    lazy = false,
    config = function()
        require("Comment").setup({
            padding = true,          -- Add space between comment and line
            sticky = true,           -- Keep comment keymap at the same place
            ignore = nil,            -- Ignore lines for commenting (nil = none)
            toggler = {
                line = "gcc",        -- Toggle comment for current line
                block = "gbc",       -- Toggle comment for block
            },
            opleader = {
                line = "gc",         -- Operator-pending mapping for line
                block = "gb",        -- Operator-pending mapping for block
            },
            mappings = {
                basic = true,         -- Enable basic mappings (gcc, gbc, gc, gb)
                extra = true,         -- Enable extra mappings (gco, gcO, gcA)
            },
        })
    end,
}