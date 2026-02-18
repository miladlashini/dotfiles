return {
    "stevearc/conform.nvim",
    event = "BufWritePre",  -- load when saving a file
    config = function()
        require("config.conform")
    end,
}
