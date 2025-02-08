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
-- require("plugins.mini")

-- VIM script configuration
vim.cmd('source ~/.config/nvim/vs_cfg.vim')
