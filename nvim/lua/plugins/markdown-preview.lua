return {
  "selimacerbas/markdown-preview.nvim",
  dependencies = { "selimacerbas/live-server.nvim" },
    config = function()
      require("config.markdown-preview")
    end,
}