local _init = function()
  local wk_available, wk = pcall(require, 'which-key')
  if wk_available then
    wk.add({
      { "<leader>c", group = "copilot", icon = "🤖" },
      { "<leader>cc", "<cmd>CopilotChatToggle<cr>", desc = "Toggle CopilotChat", icon = "🔄" },
      { "<leader>co", "<cmd>CopilotChatOpen<cr>", desc = "Open CopilotChat", icon = "💬" },
      { "<leader>cq", "<cmd>CopilotChatClose<cr>", desc = "Close CopilotChat", icon = "❌" },
      { "<leader>cs", "<cmd>CopilotChatStop<cr>", desc = "Stop CopilotChat", icon = "⏹️" },
      { "<leader>cn", "<cmd>CopilotChatReset<cr>", desc = "New CopilotChat session", icon = "🆕" },
    })
  end
end

return {
  "CopilotC-Nvim/CopilotChat.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  build = "make tiktoken",
  init = _init,
  cmd = {
    "CopilotChat",
    "CopilotChatClose",
    "CopilotChatLoad",
    "CopilotChatModels",
    "CopilotChatOpen",
    "CopilotChatPrompts",
    "CopilotChatReset",
    "CopilotChatSave",
    "CopilotChatStop",
    "CopilotChatToggle",
  },
  opts = {},
  keys = {
    { "<leader>cc", "<cmd>CopilotChatToggle<cr>", desc = "Toggle CopilotChat" },
    { "<leader>co", "<cmd>CopilotChatOpen<cr>",   desc = "Open CopilotChat" },
    { "<leader>cq", "<cmd>CopilotChatClose<cr>",  desc = "Close CopilotChat" },
    { "<leader>cs", "<cmd>CopilotChatStop<cr>",   desc = "Stop CopilotChat" },
    { "<leader>cn", "<cmd>CopilotChatReset<cr>",  desc = "New CopilotChat session" },
  },
}