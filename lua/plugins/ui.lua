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

-- Transfer Upload status icon
local function transfer_upload_status()
  local enabled = _G.transfer_upload_auto_enabled
  if enabled then
    return "󰅧"
  else
    return "󰅤 "
  end
end

lualine.setup {
    options = {
        icons_enabled = true,
        theme = 'auto',
        component_separators = { left = '', right = ''},
        section_separators = { left = '', right = ''},
        disabled_filetypes = {
            statusline = {'tagbar'},
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
        lualine_b = {{
            'diagnostics',
            source = {"nvim_diagnostic"},
            sections = { 'error', 'warn', 'info', 'hint' },
            diagnostics_color = {
                -- Same values as the general color option can be used here.
                error = 'DiagnosticError', -- Changes diagnostics' error color.
                warn  = 'DiagnosticWarn',  -- Changes diagnostics' warn color.
                info  = 'DiagnosticInfo',  -- Changes diagnostics' info color.
                hint  = 'DiagnosticHint',  -- Changes diagnostics' hint color.
            },
            symbols = { error = " ", warn = " ", hint = "󰌵 ", info = " " },
            colored = true,           -- Displays diagnostics status in color if set to true.
            update_in_insert = false, -- Update diagnostics in insert mode.
            always_visible = false,   -- Show diagnostics even if there are none.
        }},
        -- lualine_c = {'filename', configure_trouble_segment(),},
        lualine_c = {{'filename', path = 1}},  -- Show full relative path
        lualine_x = {'encoding', 'fileformat', 'filetype'},
        lualine_y = {'progress',
            {
                function() return transfer_upload_status() end, -- 使用自定义组件函数
                icon = nil, -- 可以选择性地为组件再添加一个图标 (如果函数返回的图标不够)
            },
            {
                -- recording status
                function()
                    local reg = vim.fn.reg_recording()
                    if reg ~= '' then
                        return ' ' .. reg  -- Change '' to any icon you prefer
                    end
                    return ''
                end,
                color = { fg = "#ff9e64", gui = "bold" }, -- Customize color
            }
        },
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

-- Define terminal buffers storage locally
local terminal_bufs = {}
local next_terminal_index = 1

require("bufferline").setup({
    options = {
        mode = "buffers", -- set to "tabs" to only show tabpages instead
        themable = true, -- allows highlight groups to be overriden i.e. sets highlights as default
        numbers = "ordinal", -- "ordinal", "none"
        close_command = "bdelete! %d",       -- can be a string | function, | false see "Mouse actions"
        right_mouse_command = "bdelete! %d", -- can be a string | function | false, see "Mouse actions"
        left_mouse_command = "buffer %d",    -- can be a string | function, | false see "Mouse actions"
        middle_mouse_command = nil,          -- can be a string | function, | false see "Mouse actions"
        indicator = {
            icon = '▎', -- this should be omitted if indicator style is not 'icon'
            style = 'icon',
        },
        buffer_close_icon = '󰅖',
        modified_icon = '● ',
        close_icon = ' ',
        left_trunc_marker = ' ',
        right_trunc_marker = ' ',
        -- 自定义 name_formatter 函数
        name_formatter = function(buf)
            local ft = vim.bo[buf.bufnr].filetype
            -- 处理终端缓冲区和空文件类型
            if ft == "terminal" or ft == "toggleterm" or ft == "" then
                if not terminal_bufs[buf.bufnr] then
                    terminal_bufs[buf.bufnr] = next_terminal_index
                    next_terminal_index = next_terminal_index + 1
                end
                return "term" .. terminal_bufs[buf.bufnr]
            end
            -- 其他类型缓冲区直接返回文件名
            return buf.name
        end,

        max_name_length = 18,
        max_prefix_length = 15, -- prefix used when a buffer is de-duplicated
        truncate_names = true, -- whether or not tab names should be truncated
        tab_size = 8,
        diagnostics = false,
        diagnostics_update_in_insert = false, -- only applies to coc
        diagnostics_update_on_event = true, -- use nvim's diagnostic handler
        --[[ offsets = {
           [     {
           [         filetype = "NvimTree",
           [         text = "File Explorer" | function ,
           [         text_align = "left" | "center" | "right"
           [         separator = true
           [     }
           [ }, ]]
        color_icons = true, -- whether or not to add the filetype icon highlights
        show_buffer_icons = true, -- disable filetype icons for buffers
        show_buffer_close_icons = true,
        show_close_icon = true,
        show_tab_indicators = true,
        show_duplicate_prefix = true, -- whether to show duplicate buffer prefix
        duplicates_across_groups = true, -- whether to consider duplicate paths in different groups as duplicates
        persist_buffer_sort = true, -- whether or not custom sorted buffers should persist
        move_wraps_at_ends = false, -- whether or not the move command "wraps" at the first or last position
        -- can also be a table containing 2 custom separators
        -- [focused and unfocused]. eg: { '|', '|' }
        separator_style = "slant",
        enforce_regular_tabs = false,
        always_show_bufferline = true,
        auto_toggle_bufferline = true,

        -- Filename similarity sorting
        sort_by = function(buffer_a, buffer_b)
            -- 获取文件扩展名（小写）
            local function get_extension(filename)
                return filename:match("^.+(%..+)$") or ""
            end

            local ext_a = get_extension(buffer_a.name):lower()
            local ext_b = get_extension(buffer_b.name):lower()

            -- 首先按文件类型分组
            if ext_a ~= ext_b then
                return ext_a < ext_b
            end

            -- 如果是bash文件，按打开顺序排序（bufnr越小表示越早打开）
            if ext_a == ".sh" then
                return buffer_a.bufnr < buffer_b.bufnr
            end

            -- 其他文件类型按相似度排序
            local function get_similarity_score(name1, name2)
                -- 比较时不考虑扩展名
                local base1 = name1:match("(.+)%..+$") or name1
                local base2 = name2:match("(.+)%..+$") or name2

                -- 计算最长公共前缀
                local min_len = math.min(#base1, #base2)
                local prefix_len = 0
                for i = 1, min_len do
                    if base1:sub(i, i) ~= base2:sub(i, i) then break end
                    prefix_len = i
                end

                -- 加权分数: 60% 前缀相似度, 30% 长度差异, 10% 字典序
                local prefix_score = prefix_len / min_len
                local len_score = 1 - math.abs(#base1 - #base2) / math.max(#base1, #base2)
                local lex_score = base1 < base2 and 1 or 0

                return 0.6 * prefix_score + 0.3 * len_score + 0.1 * lex_score
            end

            local similarity = get_similarity_score(buffer_a.name, buffer_b.name)

            -- 相似度阈值：低于此值视为不相似
            if similarity < 0.4 then
                -- 不相似时按文件名长度排序
                return #buffer_a.name < #buffer_b.name
            else
                -- 相似时按文件名字典序排序
                return buffer_a.name < buffer_b.name
            end
        end,
        pick = {
            alphabet = "abcdefghijklmopqrstuvwxyzABCDEFGHIJKLMOPQRSTUVWXYZ1234567890",
        },
        groups = {
            options = {
                toggle_hidden_on_enter = true  -- 重新进入隐藏组时自动展开
            },
            items = {
                {
                    name = "Term",               -- 组名（必填）
                    icon = "",                  -- 组图标（可选）
                    priority = 2,                 -- 显示优先级（可选）
                    highlight = {                 -- 高亮配置（可选）
                        underline = true,
                        sp = "blue"
                    },
                    matcher = function(buf)       -- 判断缓冲区是否属于本组（必填）
                        return buf.name:match('^term%d+$')
                    end,
                    separator = {                 -- 分隔符样式（可选）
                        style = require('bufferline.groups').separator.tab
                    }
                },
            },
        },
    },
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
