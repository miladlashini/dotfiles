return {
    "lewis6991/gitsigns.nvim",
    event = "BufReadPre",  -- load on buffer open
    config = function()
        require("config.gitsigns")
    end,
}
