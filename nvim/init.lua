--------------------------------------------------
-- LEADER
--------------------------------------------------
vim.g.mapleader = " "
vim.g.tmux_navigator_no_mappings = 1

--------------------------------------------------
-- CORE SETTINGS
--------------------------------------------------
require("core.options")
require("core.keymaps")
require("core.ui")
require("core.lazy")

--------------------------------------------------
-- PLUGINS
--------------------------------------------------
require("lazy").setup("plugins")


