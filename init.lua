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
require("plugins.codeium")

-- Snip
require("snip.cppSnip")
require("snip.cSnip")

-- VIM script configuration
vim.cmd('source ~/.config/nvim/vs_cfg.vim')
-- vim.cmd('source ~/.config/nvim/vim/log-highlight.vim')
