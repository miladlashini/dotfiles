return {
  "zbirenbaum/copilot.lua",
  cmd = "Copilot",
  event = "InsertEnter",
  config = function()
    require("copilot").setup({
      suggestion = {
        enabled = true,
        auto_trigger = true,
        keymap = {
          accept = "<C-l>",
          next = "<C-]>",
          prev = "<C-k>",   -- changed from <C-[>
          dismiss = "<C-x>",
        },
      },
      panel = { enabled = false },
    })
  end,
}