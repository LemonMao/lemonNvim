-- Gloabl Config
require('basic')
require('plugins')
require('keybindings')
require('colorscheme')

-- Plugins Config
require("plugins.ui")
require("plugins.nvim-treesitter")
require("plugins.telescope")
require("plugins.lsp")
require("plugins.format")
require("plugins.coding")
require("plugins.minuet")
require("plugins.ai")
require("plugins.complete")
require("plugins.gtags")
require("plugins.avante")
require("plugins.async-run")

-- Codeium / Windsurf
-- Check if Codeium should be enabled via environment variable
-- If CODEIUM_ENABLE is set to "1" or any non-empty value, enable Codeium
-- If CODEIUM_ENABLE is not set or set to "0", disable Codeium
local codeium_enable = os.getenv("CODEIUM_ENABLE")
local should_enable_codeium = codeium_enable and codeium_enable ~= "0"
if should_enable_codeium then
    require("plugins.codeium")
    vim.notify("Codeium enabled", vim.log.levels.INFO, { title = "Codeium" })
else
    vim.notify("Codeium disabled", vim.log.levels.INFO, { title = "Codeium" })
end

-- Snip
require("snip.cppSnip")
require("snip.cSnip")

-- VIM script configuration
vim.cmd('source ~/.config/nvim/vs_cfg.vim')
-- vim.cmd('source ~/.config/nvim/vim/log-highlight.vim')
