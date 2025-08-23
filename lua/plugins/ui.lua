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

-- Custom function to format filename for lualine
local function custom_filename_formatter()
    local full_path = vim.fn.bufname()
    local relative_path = vim.fn.fnamemodify(full_path, ":.")
    local limitation = 60 -- Threshold to trigger shortening
    local ellipsis = "..."
    local ellipsis_len = #ellipsis
    local separator_len = 1 -- for '/'

    if #relative_path <= limitation then
        return relative_path
    end

    local parts = {}
    for part in string.gmatch(relative_path, "[^/]+") do
        table.insert(parts, part)
    end

    local num_parts = #parts

    -- Handle the case where the filename itself is longer than the limitation
    local filename = parts[num_parts]
    if #filename > limitation then
        local start_len = math.floor((limitation - ellipsis_len) / 2)
        local end_len = limitation - ellipsis_len - start_len
        if start_len < 0 then
            return filename:sub(1, limitation)
        end
        return filename:sub(1, start_len) .. ellipsis .. filename:sub(#filename - end_len + 1, #filename)
    end

    local current_result_string = ""
    -- Iterate from the last part (filename) backwards
    for i = num_parts, 1, -1 do
        local part = parts[i]
        local temp_string_with_part = part
        if current_result_string ~= "" then
            temp_string_with_part = part .. "/" .. current_result_string
        end

        local potential_final_string = temp_string_with_part
        -- If there are more parts to the left, we might need an ellipsis
        if i > 1 then
            potential_final_string = ellipsis .. "/" .. temp_string_with_part
        end

        if #potential_final_string <= limitation then
            current_result_string = temp_string_with_part
        else
            -- This part (or the ellipsis) makes it too long.
            -- If we are not at the very first part of the original path, add ellipsis and break.
            if i > 1 then
                return ellipsis .. "/" .. current_result_string
            else
                -- This case should ideally not be reached if the filename itself is handled
                -- and the initial `if #relative_path <= limitation` check passes.
                -- It means the full path from `parts[1]` to `parts[num_parts]` is too long,
                -- and `parts[1]` is the only remaining part to consider.
                -- In this scenario, `current_result_string` already holds the longest possible
                -- suffix that fits within the limitation.
                return current_result_string
            end
        end
    end

    return current_result_string
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
        -- lualine_c = {custom_filename_formatter},
        lualine_c = {
            {
                'filename',
                file_status = true,      -- Displays file status (readonly status, modified status)
                newfile_status = false,  -- Display new file status (new file means no write after created)
                path = 1,                -- 0: Just the filename
                -- 1: Relative path
                -- 2: Absolute path
                -- 3: Absolute path, with tilde as the home directory
                -- 4: Filename and parent dir, with tilde as the home directory
                shorting_target = 40,    -- Shortens path to leave 40 spaces in the window for other components.
                symbols = {
                    modified = '[+]',      -- Text to show when the file is modified.
                    readonly = '[-]',      -- Text to show when the file is non-modifiable or readonly.
                    unnamed = '[No Name]', -- Text to show for unnamed buffers.
                    newfile = '[New]',     -- Text to show for newly created file before first write
                }
            }
        },
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
        numbers = "none", -- "ordinal", "none"
        close_command = "bdelete! %d",       -- can be a string | function, | false see "Mouse actions"
        right_mouse_command = "bdelete! %d", -- can be a string | function | false, see "Mouse actions"
        left_mouse_command = "buffer %d",    -- can be a string | function, | false see "Mouse actions"
        middle_mouse_command = nil,          -- can be a string | function, | false see "Mouse actions"
        indicator = {
            icon = '▎', -- this should be omitted if indicator style is not 'icon'
            style = 'icon',
        },
        buffer_close_icon = '󰅖',
        modified_icon = '  ',
        close_icon = ' ',
        left_trunc_marker = ' ',
        right_trunc_marker = ' ',
        -- 自定义 name_formatter 函数
        name_formatter = function(buf)
            -- 处理终端缓冲区和空文件类型
            if buf.name:match('term') or buf.name:match('bash') then
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
--[[
   [         sort_by = function(buffer_a, buffer_b)
   [             -- Get the filetype of the buffers
   [             local filetype_a = vim.api.nvim_get_option_value('filetype', { buf = buffer_a.bufnr })
   [             local filetype_b = vim.api.nvim_get_option_value('filetype', { buf = buffer_b.bufnr })
   [
   [             -- vim.notify_once("Get filetype: ")
   [             -- vim.notify_once("Get filetype: " .. filetype_a .. ":" .. filetype_b, vim.log.levels.INFO, { title = "Sort by type" })
   [             -- Normalize filetypes: treat 'c' and 'cpp' as the same
   [             local function normalize_filetype(ft)
   [                 if ft == 'c' or ft == 'cpp' then
   [                     return 'c_cpp'
   [                 end
   [                 return ft
   [             end
   [
   [             local normalized_ft_a = normalize_filetype(filetype_a)
   [             local normalized_ft_b = normalize_filetype(filetype_b)
   [
   [             -- First, group by filetype
   [             if normalized_ft_a ~= normalized_ft_b then
   [                 return normalized_ft_a < normalized_ft_b
   [             end
   [
   [             -- If filetypes are the same, sort by filename lexicographically
   [             return buffer_a.name < buffer_b.name
   [         end,
   ]]
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
    highlights = {
        buffer_selected = {
                fg = "#333333",
                bg = "#87CEFA",
                bold = true,
                italic = true,
        },
        modified = {
            fg = "#ff5a96",
            ctermfg = 204,
        },
        modified_visible = {
            fg = "#ff5a96",
            ctermfg = 204,
        },
        modified_selected = {
            fg = "#ff5a96",
            ctermfg = 204,
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
        side = 'left',
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
