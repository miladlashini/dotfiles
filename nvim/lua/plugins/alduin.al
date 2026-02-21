return {
  "AlessandroYorba/Alduin",
  priority = 1000,
  lazy = false,
  config = function()
    vim.opt.termguicolors = true
    vim.o.background = "dark"
    vim.cmd.colorscheme("alduin")

    --------------------------------------------------
    -- 🧼 Modern UI Cleanup
    --------------------------------------------------

    -- Transparent main background (optional)
    -- comment these 2 lines if you want solid bg
    vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
    vim.api.nvim_set_hl(0, "NormalFloat", { bg = "#1f1f1f" })

    vim.api.nvim_set_hl(0, "FloatBorder", { fg = "#d79921", bg = "#1f1f1f" })

    --------------------------------------------------
    -- 🔥 Stronger Contrast for Code
    --------------------------------------------------

    -- Comments brighter + italic
    vim.api.nvim_set_hl(0, "Comment", { fg = "#a89984", italic = true })

    -- Functions
    vim.api.nvim_set_hl(0, "@function", { fg = "#fabd2f", bold = true })

    -- Types
    vim.api.nvim_set_hl(0, "@type", { fg = "#83a598", bold = true })

    -- Keywords
    vim.api.nvim_set_hl(0, "@keyword", { fg = "#fb4934", bold = true })

    -- Strings
    vim.api.nvim_set_hl(0, "@string", { fg = "#b8bb26" })

    -- Numbers
    vim.api.nvim_set_hl(0, "@number", { fg = "#d3869b" })

    --------------------------------------------------
    -- 💡 Cursor & Selection
    --------------------------------------------------

    vim.api.nvim_set_hl(0, "CursorLine", { bg = "#2a2a2a" })
    vim.api.nvim_set_hl(0, "Visual", { bg = "#3a3a3a" })

    --------------------------------------------------
    -- 🚨 Diagnostics (Stronger & Modern)
    --------------------------------------------------

    vim.api.nvim_set_hl(0, "DiagnosticError", { fg = "#ff5f5f", bold = true })
    vim.api.nvim_set_hl(0, "DiagnosticWarn",  { fg = "#ffaa00", bold = true })
    vim.api.nvim_set_hl(0, "DiagnosticInfo",  { fg = "#5fd7ff" })
    vim.api.nvim_set_hl(0, "DiagnosticHint",  { fg = "#87ff87" })

    vim.api.nvim_set_hl(0, "DiagnosticUnderlineError", {
      undercurl = true,
      sp = "#ff5f5f",
    })

    --------------------------------------------------
    -- 🔎 LSP References
    --------------------------------------------------

    vim.api.nvim_set_hl(0, "LspReferenceText",  { bg = "#3a3a3a" })
    vim.api.nvim_set_hl(0, "LspReferenceRead",  { bg = "#3a3a3a" })
    vim.api.nvim_set_hl(0, "LspReferenceWrite", { bg = "#3a3a3a" })

    --------------------------------------------------
    -- 📦 Completion Menu (blink / cmp)
    --------------------------------------------------

    vim.api.nvim_set_hl(0, "Pmenu",      { bg = "#1f1f1f" })
    vim.api.nvim_set_hl(0, "PmenuSel",   { bg = "#3a3a3a", bold = true })
    vim.api.nvim_set_hl(0, "PmenuBorder",{ fg = "#d79921", bg = "#1f1f1f" })

    --------------------------------------------------
    -- 📌 Git Signs Contrast
    --------------------------------------------------

    vim.api.nvim_set_hl(0, "GitSignsAdd",    { fg = "#b8bb26" })
    vim.api.nvim_set_hl(0, "GitSignsChange", { fg = "#fabd2f" })
    vim.api.nvim_set_hl(0, "GitSignsDelete", { fg = "#fb4934" })
  end,
}