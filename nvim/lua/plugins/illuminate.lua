return {
  "RRethy/vim-illuminate",
  event = "BufReadPost",
  config = function()
    require("config.illuminate")
  end,
}


