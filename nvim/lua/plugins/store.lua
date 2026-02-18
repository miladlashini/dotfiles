return {
    "alex-popov-tech/store.nvim",
    dependencies = { "OXY2DEV/markview.nvim" },
    cmd = "Store",
    config = function()
        require("config.store")
    end,
}

