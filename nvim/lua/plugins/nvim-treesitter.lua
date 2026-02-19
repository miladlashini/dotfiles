return {
  {
    'nvim-treesitter/nvim-treesitter-context',
    dependencies = {
      'nvim-treesitter/nvim-treesitter',
      branch = 'main',
      build  = {
        ':TSUpdate',
      },
      config = function()
        -- ❯ rustup default stable
        -- info: using existing install for 'stable-x86_64-unknown-linux-gnu'
        -- info: default toolchain set to 'stable-x86_64-unknown-linux-gnu'
        --
        -- stable-x86_64-unknown-linux-gnu unchanged - rustc 1.92.0 (ded5c06cf 2025-12-08)
        --
        -- ❯ cargo install --locked tree-sitter-cli
        require('nvim-treesitter').install(require('config.treesitter').parsers())
      end,
    },
    event        = 'BufReadPost',
    opts         = {
      enable = true,        -- Enable this plugin (Can be enabled/disabled later via commands)
      max_lines = 0,        -- How many lines the window should span. Values <= 0 mean no limit.
      trim_scope = 'outer', -- Which context lines to discard if `max_lines` is exceeded. Choices: 'inner', 'outer'
      patterns = {
        -- Match patterns for TS nodes. These get wrapped to match at word boundaries.
        -- For all filetypes
        -- Note that setting an entry here replaces all other patterns for this entry.
        -- By setting the 'default' entry below, you can control which nodes you want to
        -- appear in the context window.
        default = {
          'class',
          'function',
          'method',
          -- 'for', -- These won't appear in the context
          -- 'while',
          -- 'if',
          -- 'switch',
          -- 'case',
        },
        -- Example for a specific filetype.
        -- If a pattern is missing, *open a PR* so everyone can benefit.
        --   rust = {
        --       'impl_item',
        --   },
      },
      exact_patterns = {
        -- Example for a specific filetype with Lua patterns
        -- Treat patterns.rust as a Lua pattern (i.e "^impl_item$" will
        -- exactly match "impl_item" only)
        -- rust = true,
      },
      -- [!] The options below are exposed but shouldn't require your attention,
      --     you can safely ignore them.

      zindex = 20,     -- The Z-index of the context window
      mode = 'cursor', -- Line used to calculate context. Choices: 'cursor', 'topline'
      separator = nil, -- Separator between context and content. Should be a single character string, like '-'.
    },
  },
}
