-- ##################
-- ## lualine
-- ##################
local status, lualine = pcall(require, "lualine")
if not status then
    vim.notify("Not find plugin lualine")
    return
end

local function configure_trouble_segment()
    local trouble = require("trouble")
    local symbols = trouble.statusline({
        mode = "lsp_document_symbols",
        groups = {},
        title = false,
        filter = { range = true },
        format = "{kind_icon}{symbol.name:Normal}",
        -- The following line is needed to fix the background color
        -- Set it to the lualine section you want to use
        hl_group = "lualine_c_normal",
    })
    return {
        symbols.get,
        cond = symbols.has,
    }
end

lualine.setup {
    options = {
        icons_enabled = true,
        theme = 'auto',
        component_separators = { left = '', right = ''},
        section_separators = { left = '', right = ''},
        disabled_filetypes = {
            statusline = {},
            winbar = {},
        },
        extensions = { "nvim-tree", "toggleterm" },
        ignore_focus = {},
        always_divide_middle = true,
        always_show_tabline = true,
        globalstatus = false,
        refresh = {
            statusline = 500,
            tabline = 500,
            winbar = 500,
        }
    },
    sections = {
        lualine_a = {
            {
                "mode",
                icons_enabled = true,
            },
        },
        lualine_b = {'diagnostics'},
        lualine_c = {'filename', configure_trouble_segment(),},
        lualine_x = {'encoding', 'fileformat', 'filetype'},
        lualine_y = {'progress'},
        lualine_z = {'location'}
    },
    inactive_sections = {
        lualine_a = {},
        lualine_b = {},
        lualine_c = {'filename'},
        lualine_x = {'progress'},
        lualine_y = {},
        lualine_z = {}
    },
    tabline = {
    },
    winbar = {
        -- lualine_a = {},
        -- lualine_b = {},
        -- lualine_c = {'filename'},
        -- lualine_x = {'progress'},
        -- lualine_y = {},
        -- lualine_z = {}
    },
    inactive_winbar = {},
    extensions = {}
}


-- ##################
-- ## bufferline
-- ##################
--
vim.opt.termguicolors = true
require("bufferline").setup({
    options = {
        mode = "buffers",
        tab_size = 5,
    }
})

-- ##################
-- ## dashboard
-- ##################
local status, db = pcall(require, "dashboard")
if not status then
    vim.notify("Not find plugin dashboard")
    return
end

db.setup({
    theme = 'doom',
    config = {
        header = {
            [[]],
            [[   ██╗     ███████╗███╗   ███╗ ██████╗ ███╗   ██╗    ██╗   ██╗██╗███╗   ███╗]],
            [[   ██║     ██╔════╝████╗ ████║██╔═══██╗████╗  ██║    ██║   ██║██║████╗ ████║]],
            [[   ██║     █████╗  ██╔████╔██║██║   ██║██╔██╗ ██║    ██║   ██║██║██╔████╔██║]],
            [[   ██║     ██╔══╝  ██║╚██╔╝██║██║   ██║██║╚██╗██║    ╚██╗ ██╔╝██║██║╚██╔╝██║]],
            [[   ███████╗███████╗██║ ╚═╝ ██║╚██████╔╝██║ ╚████║     ╚████╔╝ ██║██║ ╚═╝ ██║]],
            [[   ╚══════╝╚══════╝╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═══╝      ╚═══╝  ╚═╝╚═╝     ╚═╝]],
            [[                                              ]],
            [[             [ Happy Coding ~~~ ]              ]],
            [[]],
            [[]],
        },
        center = {
            {
                icon = "  ",
                desc = "Projects                            ",
                action = "Telescope projects",
            },
            {
                icon = "  ",
                desc = "Recently files                      ",
                action = "Telescope oldfiles",
            },
            {
                icon = "  ",
                desc = "Edit keybindings                    ",
                action = "edit ~/.config/nvim/lua/keybindings.lua",
            },
            {
                icon = "  ",
                desc = "Edit Projects                       ",
                action = "edit ~/.local/share/nvim/project_nvim/project_history",
            },
            -- {
            --   icon = "  ",
            --   desc = "Edit .bashrc                        ",
            --   action = "edit ~/.bashrc",
            -- },
            -- {
            --   icon = "  ",
            --   desc = "Change colorscheme                  ",
            --   action = "ChangeColorScheme",
            -- },
            -- {
            --   icon = "  ",
            --   desc = "Edit init.lua                       ",
            --   action = "edit ~/.config/nvim/init.lua",
            -- },
            -- {
            --   icon = "  ",
            --   desc = "Find file                           ",
            --   action = "Telescope find_files",
            -- },
            -- {
            --   icon = "  ",
            --   desc = "Find text                           ",
            --   action = "Telescopecope live_grep",
            -- },

            -- {
            --  icon = ' ',
            --  icon_hl = 'Title',
            --  desc = 'Find File           ',
            --  desc_hl = 'String',
            --  key = 'b',
            --  keymap = 'SPC f f',
            --  key_hl = 'Number',
            --  key_format = ' %s', -- remove default surrounding `[]`
            --  action = 'lua print(2)'
            --  },
        },
        footer = {
            [[]],
            [[   ⠀⠀⠀⠀⠀⠀⠀⠀⠀⡴⠞⠉⢉⣭⣿⣿⠿⣳⣤⠴⠖⠛⣛⣿⣿⡷⠖⣶⣤⡀⠀⠀⠀   ]],
            [[    ⠀⠀⠀⠀⠀⠀⠀⣼⠁⢀⣶⢻⡟⠿⠋⣴⠿⢻⣧⡴⠟⠋⠿⠛⠠⠾⢛⣵⣿⠀⠀⠀⠀  ]],
            [[    ⣼⣿⡿⢶⣄⠀⢀⡇⢀⡿⠁⠈⠀⠀⣀⣉⣀⠘⣿⠀⠀⣀⣀⠀⠀⠀⠛⡹⠋⠀⠀⠀⠀  ]],
            [[    ⣭⣤⡈⢑⣼⣻⣿⣧⡌⠁⠀⢀⣴⠟⠋⠉⠉⠛⣿⣴⠟⠋⠙⠻⣦⡰⣞⠁⢀⣤⣦⣤⠀  ]],
            [[    ⠀⠀⣰⢫⣾⠋⣽⠟⠑⠛⢠⡟⠁⠀⠀⠀⠀⠀⠈⢻⡄⠀⠀⠀⠘⣷⡈⠻⣍⠤⢤⣌⣀  ]],
            [[    ⢀⡞⣡⡌⠁⠀⠀⠀⠀⢀⣿⠁⠀⠀⠀⠀⠀⠀⠀⠀⢿⡀⠀⠀⠀⠸⣇⠀⢾⣷⢤⣬⣉  ]],
            [[    ⡞⣼⣿⣤⣄⠀⠀⠀⠀⢸⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⡇⠀⠀⠀⠀⣿⠀⠸⣿⣇⠈⠻  ]],
            [[    ⢰⣿⡿⢹⠃⠀⣠⠤⠶⣼⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⡇⠀⠀⠀⠀⣿⠀⠀⣿⠛⡄⠀  ]],
            [[    ⠈⠉⠁⠀⠀⠀⡟⡀⠀⠈⡗⠲⠶⠦⢤⣤⣤⣄⣀⣀⣸⣧⣤⣤⠤⠤⣿⣀⡀⠉⣼⡇⠀  ]],
            [[    ⣿⣴⣴⡆⠀⠀⠻⣄⠀⠀⠡⠀⠀⠀⠈⠛⠋⠀⠀⠀⡈⠀⠻⠟⠀⢀⠋⠉⠙⢷⡿⡇⠀  ]],
            [[    ⣻⡿⠏⠁⠀⠀⢠⡟⠀⠀⠀⠣⡀⠀⠀⠀⠀⠀⢀⣄⠀⠀⠀⠀⢀⠈⠀⢀⣀⡾⣴⠃⠀  ]],
            [[    ⢿⠛⠀⠀⠀⠀⢸⠁⠀⠀⠀⠀⠈⠢⠄⣀⠠⠼⣁⠀⡱⠤⠤⠐⠁⠀⠀⣸⠋⢻⡟⠀⠀  ]],
            [[    ⠈⢧⣀⣤⣶⡄⠘⣆⠀⠀⠀⠀⠀⠀⠀⢀⣤⠖⠛⠻⣄⠀⠀⠀⢀⣠⡾⠋⢀⡞⠀⠀⠀  ]],
            [[    ⠀⠀⠻⣿⣿⡇⠀⠈⠓⢦⣤⣤⣤⡤⠞⠉⠀⠀⠀⠀⠈⠛⠒⠚⢩⡅⣠⡴⠋⠀⠀⠀⠀  ]],
            [[    ⠀⠀⠀⠈⠻⢧⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠐⣻⠿⠋⠀⠀⠀⠀⠀⠀  ]],
            [[    ⠀⠀⠀⠀⠀⠀⠉⠓⠶⣤⣄⣀⡀⠀⠀⠀⠀⠀⢀⣀⣠⡴⠖⠋⠁⠀⠀⠀⠀⠀⠀⠀⠀  ]],
            [[                                       ]],
            [[                                       ]],
            [[                                       ]],
        },
    }
})

-- ##################
-- ##  noice - async message popupmenu
-- ##################
require("noice").setup({
    cmdline = {
        view = "cmdline_popup", -- view for rendering the cmdline, `cmdline`:bottom, `cmdline_popup`:top
    },
    lsp = {
        -- override markdown rendering so that **cmp** and other plugins use **Treesitter**
        override = {
            ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
            ["vim.lsp.util.stylize_markdown"] = true,
            ["cmp.entry.get_documentation"] = true, -- requires hrsh7th/nvim-cmp
        },
    },
    -- you can enable a preset for easier configuration
    presets = {
        bottom_search = true, -- use a classic bottom cmdline for search
        command_palette = true, -- position the cmdline and popupmenu together
        long_message_to_split = true, -- long messages will be sent to a split
        inc_rename = false, -- enables an input dialog for inc-rename.nvim
        lsp_doc_border = true, -- add a border to hover docs and signature help
    },
})

vim.keymap.set("n", "<leader>nl", function()
    require("noice").cmd("last")
end)

vim.keymap.set("n", "<leader>nh", function()
    require("noice").cmd("history")
end)

-- Noice help:
-- :Noice or :Noice history shows the message history
-- :Noice last shows the last message in a popup
-- :Noice dismiss dismiss all visible messages
-- :Noice errors shows the error messages in a split. Last errors on top
-- :Noice disable disables Noice
-- :Noice enable enables Noice
-- :Noice stats shows debugging stats
-- :Noice telescope opens message history in Telescope

-- ##################
-- ## ibl - indenet lines
-- ##################
local status, ibl = pcall(require, "ibl")
if not status then
    vim.notify("Not find plugin indent-blankline")
    return
end

ibl.setup({
    indent = {
        -- char = "│",
        char = '¦',
        -- char = '┆',
        -- char = '│',
        -- char = "⎸",
        tab_char = "│",
    },
    scope = { show_start = false, show_end = false },
    -- type `:echo &filetype` and add the result into exclude.filetypes
    exclude = {
        filetypes = {
            "Trouble",
            "alpha",
            "dashboard",
            "help",
            "lazy",
            "mason",
            "neo-tree",
            "notify",
            "snacks_dashboard",
            "snacks_notif",
            "snacks_terminal",
            "snacks_win",
            "toggleterm",
            "trouble",
            "log",
            "markdown",
            "TelescopePrompt",
            "lspinfo",
        },
    },
})

-- ##################
-- ## nvim-tree: directory tree
-- ##################
local status, nvim_tree = pcall(require, "nvim-tree")
if not status then
    vim.notify("Not find nvim-tree")
    return
end

-- 列表操作快捷键
nvim_tree.setup({
    sort_by = "case_sensitive",
    -- 不显示 git 状态图标
    git = {
        enable = false,
    },
    -- project plugin 需要这样设置
    sync_root_with_cwd = false,
    respect_buf_cwd = false,
    update_focused_file = {
        enable = true,
        update_cwd = true,
    },
    -- 隐藏 .文件 和 node_modules 文件夹
    filters = {
        dotfiles = true,
        custom = { 'node_modules' },
    },
    view = {
        -- 宽度
        width = 40,
        -- 也可以 'right'
        side = 'right',
        -- 不显示行数
        number = false,
        relativenumber = false,
        -- 显示图标
        signcolumn = 'yes',
    },
    actions = {
        open_file = {
            -- 首次打开大小适配
            resize_window = true,
            -- 打开文件时关闭
            quit_on_open = true,
        },
    },
    -- wsl install -g wsl-open
    -- https://github.com/4U6U57/wsl-open/
    system_open = {
        cmd = 'wsl-open', -- mac 直接设置为 open
    },
    renderer = {
        group_empty = true,
    },
})
-- 自动关闭
vim.cmd([[
  autocmd BufEnter * ++nested if winnr('$') == 1 && bufname() == 'NvimTree_' . tabpagenr() | quit | endif
]])

-- ##################
-- ## which-key
-- ##################
--
-- ##################
-- ##
-- ##################
--
