return {
    "williamboman/mason.nvim",
    cmd = "Mason",  -- lazy load when :Mason is used
    config = function()
        require("config.mason")
    end,
}
