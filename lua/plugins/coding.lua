-- ## ------------------------------ ##
-- ## Trouble & Diagnostic
-- ## ------------------------------ ##
vim.diagnostic.config({
    virtual_text = true,
    signs = true,
    update_in_insert = true,
})

local signs = { Error = "", Warn = "", Hint = "󰌵", Info = "" }
for type, icon in pairs(signs) do
    local hl = "DiagnosticSign" .. type
    vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
end
for type, icon in pairs(signs) do
    local hl = "DiagnosticSign" .. type
    vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
end

-- Disable diagnostics globally by default
-- vim.diagnostic.enable()
vim.diagnostic.disable()

-- func toggle_diagnostics for keybinds
function toggle_diagnostics()
    if vim.diagnostic.is_enabled() then
        vim.diagnostic.disable()
    else
        vim.diagnostic.enable()
    end
end

-- Automatically Open Trouble Quickfix
vim.api.nvim_create_autocmd("QuickFixCmdPost", {
    callback = function()
        vim.cmd([[Trouble qflist open]])
    end,
})

-- require("trouble").setup{}



-- ## ------------------------------ ##
-- ## Mini
-- ## ------------------------------ ##
require('mini.animate').setup()
require('mini.comment').setup({
    mappings = {
        options = {
            custom_commentstring = nul,
        },
        -- Toggle comment (like `gcip` - comment inner paragraph) for both
        -- Normal and Visual modes
        comment = '<leader>cs',

        -- Toggle comment on current line
        comment_line = '<leader>cc',

        -- Toggle comment on visual selection
        comment_visual = '<leader>cs',

        -- Define 'comment' textobject (like `dgc` - delete whole comment block)
        -- Works also in Visual mode if mapping differs from `comment_visual`
        textobject = '<leader>cs',
    }
})
require('mini.cursorword').setup()
require('mini.hipatterns').setup({
    highlighters = {
        -- Highlight standalone 'FIXME', 'HACK', 'TODO', 'NOTE'
        fixme = { pattern = '%f[%w]()FIXME()%f[%W]', group = 'MiniHipatternsFixme' },
        hack  = { pattern = '%f[%w]()HACK()%f[%W]',  group = 'MiniHipatternsHack'  },
        todo  = { pattern = '%f[%w]()TODO()%f[%W]',  group = 'MiniHipatternsTodo'  },
        note  = { pattern = '%f[%w]()NOTE()%f[%W]',  group = 'MiniHipatternsNote'  },

        -- Highlight hex color strings (`#rrggbb`) using that color
        hex_color = require('mini.hipatterns').gen_highlighter.hex_color(),
    },
})
require('mini.align').setup({
    -- s：输入分隔模式（分割符号）。
    -- j：选择对齐的方向（左对齐、居中对齐、右对齐）。
    -- m：输入合并分隔符。
    -- f：输入 Lua 表达式过滤对齐部分。
    -- i：忽略一些不需要对齐的部分。
    -- p：将相邻部分配对对齐。
    -- t：去除部分的空白字符。
    -- <BS>：删除上一步操作。
    mappings = {
        start = '<leader>l', -- `,a=` align by `=`
        start_with_preview = '<leader>L', -- interaction mode
    },
    silent = false,
})
require('mini.pairs').setup()
require('mini.splitjoin').setup({
    mappings = {
        toggle = '<leader>S',  -- 切换（Toggle）的快捷键
        split = '',     -- 拆分（Split）的快捷键，默认为禁用
        join = '',      -- 合并（Join）的快捷键，默认为禁用
    },
    detect = {
        brackets = nil,  -- 检测参数的括号类型（默认为 { '%b()', '%b[]', '%b{}' }）
        separator = ',', -- 参数分隔符
        exclude_regions = nil,  -- 排除区域的模式（例如嵌套括号和引号）
    },
})
-- add/delete surround character like '(' for strings
require('mini.surround').setup({
    custom_surroundings = nil,
    highlight_duration = 500,
    mappings = {
        add = '<leader>ra',
        delete = '<leader>rd',
        find = '<leader>rf',
        replace = '<leader>rr',
        find_left = '<leader>rF',
        highlight = '<leader>rh',
        update_n_lines = '<leader>rn',
        suffix_last = 'l',
        suffix_next = 'n',
    },
    n_lines = 20,
    respect_selection_type = false,
    search_method = 'cover',
    silent = false,
})

-- ## ------------------------------ ##
-- ## Others
-- ## ------------------------------ ##
require('trim').setup({
    -- if you want to ignore markdown file, you can specify filetypes.
    -- ft_blocklist = {"markdown", "dashboard", "mason", "notify"},
    ft_blocklist = {"dashboard", ""},
    -- if you want to disable trim on write by default
    trim_on_write = false,
    -- highlight trailing spaces
    highlight = true
})


require("interestingwords").setup {
    colors = {
        '#aeee00',  -- Light green
        '#ff0000',  -- Red
        '#0000ff',  -- Blue
        '#b88823',  -- Brown
        '#ffa724',  -- Orange
        '#ff2c4b',  -- Pink-ish red
        '#00ffff',  -- Cyan
        '#ff00ff',  -- Magenta
        '#ffff00',  -- Yellow
        '#8b4513',  -- Saddle brown
        '#4682b4',  -- Steel blue
        '#d2691e',  -- Chocolate
        '#c71585',  -- Medium violet red
        '#40e0d0',  -- Turquoise
        '#ffd700',  -- Gold
    },
    search_count = true,
    navigation = false,
    scroll_center = true,
    search_key = "<leader>k",
    cancel_search_key = "<leader>K",
    color_key = "<leader>s8",
    cancel_color_key = "<leader>s9",
    select_mode = "random",  -- random or loop
}


-- ## ------------------------------ ##
-- ## Git
-- ## ------------------------------ ##
require('blame').setup (
    {
        date_format = "%d.%m.%Y",
        virtual_style = "right_align",
        views = {
            window = window_view,
            virtual = virtual_view,
            default = window_view,
        },
        focus_blame = true,
        merge_consecutive = false,
        max_summary_width = 30,
        colors = nil,
        blame_options = nil,
        commit_detail_view = "vsplit",
        mappings = {
            commit_info = "i",
            stack_push = "<TAB>",
            stack_pop = "<BS>",
            show_commit = "<CR>",
            close = { "<esc>", "q" },
        }
    }
)
require('diffview').setup()

-- ## ------------------------------ ##
-- ## project
-- ## ------------------------------ ##
local status, project = pcall(require, "project_nvim")
if not status then
    vim.notify("没有找到 project_nvim")
  return
end

-- nvim-tree 支持
vim.g.nvim_tree_respect_buf_cwd = 1

project.setup({
  -- Manual mode doesn't automatically change your root directory, so you have
  -- the option to manually do so using `:ProjectRoot` command.
  manual_mode = false,

  -- Methods of detecting the root directory. **"lsp"** uses the native neovim
  -- lsp, while **"pattern"** uses vim-rooter like glob pattern matching. Here
  -- order matters: if one is not detected, the other is used as fallback. You
  -- can also delete or rearangne the detection methods.
  detection_methods = { "lsp", "pattern" },

  -- All the patterns used to detect root dir, when **"pattern"** is in
  -- detection_methods
  patterns = { ".git", ".svn", ".root" },

  -- Table of lsp clients to ignore by name
  -- eg: { "efm", ... }
  ignore_lsp = {},

  -- Don't calculate root dir on specific directories
  -- Ex: { "~/.cargo/*", ... }
  exclude_dirs = {},

  -- Show hidden files in telescope
  show_hidden = false,

  -- When set to false, you will get a message when project.nvim changes your
  -- directory.
  silent_chdir = false,

  -- What scope to change the directory, valid options are
  -- * global (default)
  -- * tab
  -- * win
  scope_chdir = 'global',

  -- Path where project.nvim will store the project history for use in
  -- telescope.  ~/.local/share/nvim
  datapath = vim.fn.stdpath("data"),

})

local status, telescope = pcall(require, "telescope")
if not status then
  vim.notify("没有找到 telescope")
  return
end
pcall(telescope.load_extension, "projects")
-- ## ------------------------------ ##
-- ## AI Codeium
-- ## ------------------------------ ##
--
-- The plugin log is written to ~/.cache/nvim/codeium/codeium.log.
-- You can set the logging level to one of "trace/debug/info/warn/error"
-- by exporting the `DEBUG_CODEIUM` environment variable.
--
require("codeium").setup({
    -- Optionally disable cmp source if using virtual text only
    enable_cmp_source = false,
    enterprise_mode = true,
    enable_chat = false,

    api = {
        -- the hostname. Example: "codeium.example.com". Required when using enterprise mode
        host = "codeium.delllabs.net",
        -- the port. Defaults to 443
        port = 443,
        -- the path prefix to the API server. Default for enterprise: "/_route/api_server"
        path = "/_route/api_server",
        -- the portal URL to use (for enterprise mode). Defaults to host:port
        portal_url = nil,
    },

    virtual_text = {
        enabled = true,

        -- These are the defaults

        -- Set to true if you never want completions to be shown automatically.
        manual = false,
        -- A mapping of filetype to true or false, to enable virtual text.
        filetypes = {},
        -- Whether to enable virtual text of not for filetypes not specifically listed above.
        default_filetype_enabled = true,
        -- filetypes = {
        --     python = true,
        --     markdown = false
        -- },
        -- default_filetype_enabled = true,

        -- How long to wait (in ms) before requesting completions after typing stops.
        idle_delay = 300,
        -- Priority of the virtual text. This usually ensures that the completions appear on top of
        -- other plugins that also add virtual text, such as LSP inlay hints, but can be modified if
        -- desired.
        virtual_text_priority = 65535,
        -- Set to false to disable all key bindings for managing completions.
        map_keys = true,
        -- The key to press when hitting the accept keybinding but no completion is showing.
        -- Defaults to \t normally or <c-n> when a popup is showing.
        accept_fallback = nil,
        -- Key bindings for managing completions in virtual text mode.
        key_bindings = {
            -- Accept the current completion.
            accept = "<C-k>",
            -- Accept the next word.
            accept_word = false,
            -- Accept the next line.
            accept_line = false,
            -- Clear the virtual text.
            clear = false,
            -- Cycle to the next completion.
            next = "<C-n>",
            -- Cycle to the previous completion.
            prev = "<C-p>",
        }
    },
    workspace_root = {
        use_lsp = true,
        find_root = nil,
        paths = {
            ".git",
            ".svn",
        },
    },
})

-- Codeium Auto Toggle. It is enabled at NVIM launch. Use this command to toggle the
-- enable/disable for Codeium feature.
local codeium_config = require("codeium.config").options
vim.api.nvim_create_user_command('CodeiumToggle', function()
    codeium_config.virtual_text.enabled = not codeium_config.virtual_text.enabled
    require("codeium").setup(codeium_config)

    if codeium_config.virtual_text.enabled then
        vim.notify("Codeium enabled: ON", vim.log.levels.INFO, { title = "Codeium" })
    else
        vim.notify("Codeium enabled: OFF", vim.log.levels.INFO, { title = "Codeium" })
    end
end, { desc = "Toggle Codeium" })

--
require('codeium.virtual_text').set_statusbar_refresh(function()
    require('lualine').refresh()
end)

-- ## ------------------------------ ##
-- ## Transfer
-- ## ------------------------------ ##
--
-- 存储 TransferUpload 自动化状态的全局变量，默认为禁用 (false)
_G.transfer_upload_auto_enabled = false

vim.api.nvim_create_user_command('TransferToggle', function()
  -- 切换全局变量的状态 (true 变为 false, false 变为 true)
  _G.transfer_upload_auto_enabled = not _G.transfer_upload_auto_enabled

  if _G.transfer_upload_auto_enabled then
    vim.notify("TransferUpload 自动化: 启用", vim.log.levels.INFO, { title = "TransferToggle" })
  else
    vim.notify("TransferUpload 自动化: 禁用", vim.log.levels.INFO, { title = "TransferToggle" })
  end
end, { desc = "切换 Buffer 保存时自动 TransferUpload 功能" })

vim.api.nvim_create_autocmd("BufWritePost", {
  group = vim.api.nvim_create_augroup("TransferUploadAutoCmd", { clear = true }),
  callback = function()
    -- 检查全局变量 _G.transfer_upload_auto_enabled 是否为 true (启用状态)
    if _G.transfer_upload_auto_enabled then
      -- 执行 TransferUpload 命令
      vim.cmd('TransferUpload')
    end
  end,
  desc = "Buffer 保存后自动执行 TransferUpload (可使用 :TransferToggle 切换开关)",
})
-- ## ------------------------------ ##
-- ##
-- ## ------------------------------ ##
--
