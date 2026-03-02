-- plugin manager
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable", -- latest stable release
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
    -- ############
    -- Scheme
    -- ############
    {
        "folke/tokyonight.nvim",
        lazy = false,
        priority = 1000,
        opts = {},
    },
    { "catppuccin/nvim", name = "catppuccin", priority = 1000, lazy = false },
    -- ############
    -- Search
    -- ############
    {
        "nvim-telescope/telescope.nvim",
        tag = "0.1.8",
        lazy = false,
        dependencies = { "nvim-lua/plenary.nvim" },
    },
    -- ############
    -- AI
    -- ############
    {
        "yetone/avante.nvim",
        event = "VeryLazy",
        lazy = false,
        version = false, -- Set this to "*" to always pull the latest release version, or set it to false to update to the latest code changes.
        keys = {
            {
                "<leader>a=",
                function()
                    local tree_ext = require("avante.extensions.nvim_tree")
                    tree_ext.add_file()
                end,
                desc = "Select file in NvimTree",
                ft = "NvimTree",
            },
            {
                "<leader>a-",
                function()
                    local tree_ext = require("avante.extensions.nvim_tree")
                    tree_ext.remove_file()
                end,
                desc = "Deselect file in NvimTree",
                ft = "NvimTree",
            },
        },
        -- opts = require("plugins.avante").opts,
        -- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
        build = "make",
        -- build = "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false" -- for windows
        dependencies = {
            "nvim-lua/plenary.nvim",
            "MunifTanjim/nui.nvim",
            --- The below dependencies are optional,
            "nvim-telescope/telescope.nvim", -- for file_selector provider telescope
            "hrsh7th/nvim-cmp", -- autocompletion for avante commands and mentions
            "stevearc/dressing.nvim", -- for input provider dressing
            "nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
        },
    },
    {
        "Exafunction/windsurf.nvim",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "hrsh7th/nvim-cmp",
        },
    },
    {
        'milanglacier/minuet-ai.nvim',
        dependencies = {
            "nvim-lua/plenary.nvim",
        },
    },
    {
        -- https://codecompanion.olimorris.dev/installation
        "olimorris/codecompanion.nvim",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-treesitter/nvim-treesitter",
            "ravitemer/codecompanion-history.nvim",
            "franco-ruggeri/codecompanion-lualine.nvim",
            "franco-ruggeri/codecompanion-spinner.nvim",
        },
    },
    --
    -- ############
    -- UI - ui.lua
    -- ############
    {
        -- stats line
        "nvim-lualine/lualine.nvim",
        version = "*", lazy = false,
        dependencies = { "nvim-tree/nvim-web-devicons" },
    },
    {
        -- dir tree
        "nvim-tree/nvim-tree.lua",
        version = "*", lazy = false,
        dependencies = { "nvim-tree/nvim-web-devicons" },
    },
    {
        "nvimdev/dashboard-nvim",
        version = "*", lazy = false, event = "VimEnter",
        dependencies = { { "nvim-tree/nvim-web-devicons" } },
    },
    {
        "folke/noice.nvim",
        lazy = false,
        -- event = "VeryLazy",
        dependencies = {
            -- if you lazy-load any plugin below, make sure to add proper `module="..."` entries
            "MunifTanjim/nui.nvim",
            -- OPTIONAL:
            --   `nvim-notify` is only needed, if you want to use the notification view.
            --   If not available, we use `mini` as the fallback
            "rcarriga/nvim-notify",
        }
    },
    {
        "lukas-reineke/indent-blankline.nvim",
    },
    {
        -- Make sure to set this up properly if you have lazy=true
        'MeanderingProgrammer/render-markdown.nvim',
        dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' },
        opts = {
            file_types = { "markdown", "Avante", "codecompanion" },
        },
        ft = { "markdown", "Avante", "codecompanion" },
    },
    {
        'akinsho/bufferline.nvim',
        version = "*",
        dependencies = 'nvim-tree/nvim-web-devicons'
    },
    --[[
       [ {
       [     "3rd/image.nvim",
       [     build = false, -- so that it doesn't build the rock https://github.com/3rd/image.nvim/issues/91#issuecomment-2453430239
       [     opts = {
       [         processor = "magick_cli",
       [     }
       [ },
       ]]
    --
    -- {
    --     "folke/which-key.nvim",
    --     event = "VeryLazy",
    --     keys = {
    --         {
    --             "<leader>?",
    --             function()
    --                 require("which-key").show({ global = false })
    --             end,
    --             desc = "Buffer Local Keymaps (which-key)",
    --         },
    --     },
    -- },
    -- ############
    -- LSP - lsp.lua
    -- ############
    {
        "neovim/nvim-lspconfig",
    },
    {
        "williamboman/mason.nvim",
        "williamboman/mason-lspconfig.nvim",
    },
    {

        "p00f/clangd_extensions.nvim",
        lazy = true,
    },
    -- ############
    -- gtags
    -- ############
    {
        "dhananjaylatkar/cscope_maps.nvim",
    },
    {
        "ludovicchabant/vim-gutentags",
        init = function()
            -- vim.g.gutentags_modules = {"cscope_maps"} -- This is required. Other config is optional
            -- vim.g.gutentags_cscope_build_inverted_index_maps = 1
            -- vim.g.gutentags_file_list_command = "fd -e c -e h"
            -- vim.g.gutentags_cache_dir = vim.fn.expand("~/.cache/tags")
            -- vim.g.gutentags_trace = 1
        end,
    },

    -- ############
    -- coding
    -- ############
    {
        "ahmedkhalf/project.nvim",
        version = "*",
        lazy = false,
    },
    {
        -- code modern highlight
        "nvim-treesitter/nvim-treesitter",
        version = "*",
        lazy = false,
        build = ":TSUpdate",
    },
    {
        "nvim-treesitter/nvim-treesitter-textobjects",
    },
    {
        -- code format
        "stevearc/conform.nvim",
    },
    {
        -- code complete
        "hrsh7th/nvim-cmp",
        version = false, -- last release is way too old
        -- event = "InsertEnter",
        dependencies = {
            "hrsh7th/cmp-nvim-lsp",
            "hrsh7th/cmp-buffer",
            "hrsh7th/cmp-path",
            "hrsh7th/cmp-cmdline",
            -- "hrsh7th/cmp-vsnip",
            -- "hrsh7th/vim-vsnip",
            -- "hrsh7th/vim-vsnip-integ",
            "L3MON4D3/LuaSnip",
            "saadparwaiz1/cmp_luasnip",
            build = "make install_jsregexp",
        },
    },
    {
        'scrooloose/nerdcommenter',
    },
    {
        -- code tools
        "echasnovski/mini.animate",
        "echasnovski/mini.cursorword",
        "echasnovski/mini.hipatterns",
        "echasnovski/mini.align",
        'echasnovski/mini.pairs',
        'echasnovski/mini.splitjoin',
        'echasnovski/mini.surround',
    },
    { -- trim tail white space
        "cappyzawa/trim.nvim",
        priority = 1002,
    },
    { -- highlight word
        "Mr-LLLLL/interestingwords.nvim",
        -- "vim-scripts/Mark",
    },
    { -- strcutre tag list
        'preservim/tagbar',
        event = VeryLazy,
        config = function()
            -- nothing
        end
    },
    {
        -- diagnos
        "folke/trouble.nvim",
        opts = require("plugins.trouble").opts,
        cmd = "Trouble",
    },
    {
        -- Git tools: blame/diff
        "FabijanZulj/blame.nvim",
        "sindrets/diffview.nvim",
        lazy = true,
    },
    {
        "skywind3000/vim-preview",
    },
    {
        "coffebar/transfer.nvim",
        lazy = true,
        cmd = { "TransferInit", "DiffRemote", "TransferUpload", "TransferDownload", "TransferDirDiff", "TransferRepeat" },
        opts = {},
    },
    {
        "gauteh/vim-cppman",
    },
    {
        'fei6409/log-highlight.nvim',
        opts = {},
    },
    -- Plugin End
})
