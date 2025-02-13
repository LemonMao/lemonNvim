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
        opts = require("plugins.codingCfg").avanteOpts,
        -- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
        build = "make",
        -- build = "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false" -- for windows
        dependencies = {
            "stevearc/dressing.nvim",
            "nvim-lua/plenary.nvim",
            "MunifTanjim/nui.nvim",
            --- The below dependencies are optional,
            "nvim-telescope/telescope.nvim", -- for file_selector provider telescope
            "hrsh7th/nvim-cmp", -- autocompletion for avante commands and mentions
            "nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
            "zbirenbaum/copilot.lua", -- for providers='copilot'
            {
                -- support for image pasting
                "HakonHarnes/img-clip.nvim",
                event = "VeryLazy",
                opts = {
                    -- recommended settings
                    default = {
                        embed_image_as_base64 = false,
                        prompt_for_file_name = false,
                        drag_and_drop = {
                            insert_mode = true,
                        },
                        -- required for Windows users
                        use_absolute_path = true,
                    },
                },
            },
        },
    },
    {
        "Exafunction/codeium.nvim",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "hrsh7th/nvim-cmp",
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
            file_types = { "markdown", "Avante" },
        },
        ft = { "markdown", "Avante" },
    },
    {
        'akinsho/bufferline.nvim',
        version = "*",
        dependencies = 'nvim-tree/nvim-web-devicons'
    },
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
            "hrsh7th/cmp-vsnip",
            "hrsh7th/vim-vsnip",
            -- "L3MON4D3/LuaSnipk",
            -- "saadparwaiz1/cmp_luasnip",
        },
    },
    {
        -- code tools
        "kechasnovski/mini.animate",
        "echasnovski/mini.comment",
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
        opts = require("plugins.codingCfg").troubleOpts,
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
    -- Plugin End
})
