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
require("plugins.complete")
require("plugins.coding")
require("plugins.gtags")
require("plugins.avante")
require("plugins.async-run")

-- Codeium / Windsurf
-- Check if Codeium should be disabled via environment variable
-- If CODEIUM_DISABLE is set and its value is not '0', skip setup
local codeium_disable = os.getenv("CODEIUM_DISABLE")
local should_enable_codeium = not (codeium_disable and codeium_disable ~= "0")
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
