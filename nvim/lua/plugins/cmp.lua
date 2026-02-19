---@diagnostic disable: undefined-doc-name
local _list = {
  -- when nothing is preselected, using <Tab>/<C-n> the first time will
  -- select the first entry & feed it into the current cursor position
  selection = {
    preselect = false,
  },
}

return {
  'saghen/blink.cmp',
  dependencies = {
    { 'L3MON4D3/LuaSnip' },
    {
      "zbirenbaum/copilot.lua",
      cmd = "Copilot",
      event = "InsertEnter",
      opts = {
        suggestion = { enabled = false }, -- Disable inline suggestions (using blink-copilot instead)
        panel = { enabled = false, },
      }
    },
    {
      "fang2hou/blink-copilot",
      opts = {
        max_completions = 3, -- Global default for max completions
        max_attempts = 2,    -- Global default for max attempts
      },
    }
  },
  event        = {
    'InsertEnter',
    'CmdlineEnter',
  },
  version      = '1.*',
  ---@module 'blink.cmp'
  ---@type blink.cmp.Config
  opts         = {
    cmdline = {
      completion = {
        list = _list,
        menu = {
          -- automatically open completion menu;
          -- when set to 'false' it needs to be triggered with <tab>
          auto_show = true,
        },
      },
    },
    completion = {
      documentation = {
        auto_show = true,
        auto_show_delay_ms = 500,
      },
      list = _list,
      menu = {
        auto_show = true,
        border = {
          { "╭", "CmpBorder" },
          { "─", "CmpBorder" },
          { "╮", "CmpBorder" },
          { "│", "CmpBorder" },
          { "╯", "CmpBorder" },
          { "─", "CmpBorder" },
          { "╰", "CmpBorder" },
          { "│", "CmpBorder" },
        },
        draw = {
          columns = {
            { "label", "label_description", gap = 1 }, { "kind_icon", "kind" }
          },
        },
      },
    },
    keymap = {
      ['<CR>']    = { 'select_and_accept', 'fallback' },
      ['<DOWN>']   = { 'select_next', 'fallback_to_mappings' },
      ['<UP>'] = { 'select_prev', 'fallback_to_mappings' },
    },
    -- ensure you have the `snippets` source (enabled by default)
    sources = {
      default = { 'lsp', 'path', 'snippets', 'buffer', 'cmdline', 'copilot' },
      providers = {
        copilot = {
          name = "copilot",
          module = "blink-copilot",
          score_offset = 100,
          async = true,
        },
      },
    },
  },
}