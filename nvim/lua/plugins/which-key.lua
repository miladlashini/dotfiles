return {
    "folke/which-key.nvim",
    event = "VeryLazy",  -- recommended lazy load
    config = function()
        require("config.which-key")
    end,
}
