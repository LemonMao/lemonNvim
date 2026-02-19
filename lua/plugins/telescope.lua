local status, telescope = pcall(require, "telescope")
if not status then
    vim.notify("Not find plugin telescope")
    return
end

-- Telescope 列表中 插入模式快捷键
local open_with_trouble = require("trouble.sources.telescope").open
-- Use this to add more results without clearing the trouble list
-- local add_to_trouble = require("trouble.sources.telescope").add

-- 导入 actions 模块用于多选功能
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

-- 调试函数：查看当前选择状态
local function debug_selection(prompt_bufnr)
    local picker = action_state.get_current_picker(prompt_bufnr)
    local selections = picker:get_multi_selection()
    vim.notify("当前选择了 " .. #selections .. " 个项目", vim.log.levels.INFO)
    for i, entry in ipairs(selections) do
        print(string.format("选择 %d: ", i))
        if entry.path then
            print("  路径: " .. entry.path)
        end
        if entry.value then
            print("  值: " .. tostring(entry.value))
        end
        if entry.bufnr then
            print("  缓冲区: " .. entry.bufnr)
        end
    end
end

-- 自定义多选打开函数
local function multi_open(prompt_bufnr)
    local picker = action_state.get_current_picker(prompt_bufnr)
    local selections = picker:get_multi_selection()

    -- 调试信息
    vim.notify("multi_open 被调用，选择了 " .. #selections .. " 个项目", vim.log.levels.INFO)

    if #selections == 0 then
        -- 如果没有多选，执行默认操作
        vim.notify("没有多选，执行默认操作", vim.log.levels.INFO)
        actions.select_default(prompt_bufnr)
    else
        -- 关闭 Telescope 窗口
        actions.close(prompt_bufnr)

        -- 对每个选中的项目执行操作
        for _, entry in ipairs(selections) do
            if entry.path then
                -- 如果是文件，在新标签页中打开
                vim.cmd("tabnew " .. vim.fn.fnameescape(entry.path))
                vim.notify("打开文件: " .. entry.path, vim.log.levels.INFO)
            elseif entry.value then
                -- 如果是其他类型的结果
                vim.notify("选中: " .. tostring(entry.value), vim.log.levels.INFO)
            elseif entry.bufnr then
                -- 如果是缓冲区，切换到该缓冲区
                vim.cmd("buffer " .. entry.bufnr)
                vim.notify("切换到缓冲区: " .. entry.bufnr, vim.log.levels.INFO)
            end
        end
    end
end

telescope.setup({
    defaults = {
        -- 打开弹窗后进入的初始模式，默认为 insert，也可以是 normal
        initial_mode = "insert",

        -- 多选相关配置
        selection_strategy = "reset",  -- 或 "follow"
        sorting_strategy = "descending",  -- 或 "ascending"

        -- 布局配置
        layout_strategy = "horizontal",
        layout_config = {
            width = 0.95,
            height = 0.85,
            preview_cutoff = 120,
        },

        -- 文件忽略模式
        file_ignore_patterns = {
            "node_modules",
            ".git",
            ".cache",
            "__pycache__",
            "*.pyc",
        },

        -- 颜色高亮
        color_devicons = true,

        -- 窗口内快捷键
        mappings = {
            i = {
                -- 上下移动
                ["<C-j>"] = "move_selection_next",
                ["<C-k>"] = "move_selection_previous",
                ["<Down>"] = "move_selection_next",
                ["<Up>"] = "move_selection_previous",
                -- 历史记录
                ["<C-n>"] = "cycle_history_next",
                ["<C-p>"] = "cycle_history_prev",
                -- 关闭窗口
                ["<C-c>"] = "close",
                -- 预览窗口上下滚动
                ["<A-u>"] = "preview_scrolling_up",
                ["<A-d>"] = "preview_scrolling_down",
                ["g?"] = "which_key",
                ["<C-x>"] = "delete_buffer",
                ["<ESC>"] = "close",
                ["<c-t>"] = open_with_trouble,

                -- 多选功能快捷键
                ["<C-i>"] = actions.toggle_selection,      -- 切换选择
                ["<C-a>"] = actions.add_selectiong             -- 添加到选择
                ["<C-s>"] = actions.select_all,                -- 全选
                ["<C-u>"] = actions.drop_all,                  -- 取消全选

                -- 调试快捷键
                ["<F2>"] = debug_selection,                    -- 查看选择状态

                -- 自定义回车行为（多选打开）
                ["<CR>"] = multi_open,

                -- 其他快捷键
                ["<Tab>"] = actions.toggle_selection + actions.move_selection_worse,
                ["<S-Tab>"] = actions.toggle_selection + actions.move_selection_better,
            },
            n = {
                ["<c-t>"] = open_with_trouble,
                -- 正常模式多选快捷键
                ["<space>"] = actions.toggle_selection,      -- 切换选择
                ["a"] = actions.add_selection,             -- 添加到选择
                ["x"] = actions.remove_selection,          -- 从选择中移除
                ["<C-a>"] = actions.select_all,            -- 全选
                ["<C-u>"] = actions.drop_all,              -- 取消全选

                -- 调试快捷键
                ["<F2>"] = debug_selection,                -- 查看选择状态

                ["<CR>"] = multi_open,
                ["q"] = actions.close,
                ["<Esc>"] = actions.close,
            },
        },
    },
    pickers = {
        -- 内置 pickers 配置
        find_files = {
            -- 查找文件换皮肤，支持的参数有： dropdown, cursor, ivy
            -- theme = "dropdown",
            previewer = false,
        },
        buffers = {
            -- 查找文件换皮肤，支持的参数有： dropdown, cursor, ivy
            -- theme = "dropdown",
            previewer = false,
            sort_lastused = true,
            ignore_current_buffer = true,
        },
        oldfiles = {
            -- 查找文件换皮肤，支持的参数有： dropdown, cursor, ivy
            -- theme = "dropdown",
            previewer = false,
        },
    },
    extensions = {
        -- 扩展插件配置
    },
})

-- 多选功能使用说明：
-- 1. 基本操作：
--    - 插入模式：<C-space> 切换选择，<C-a> 添加到选择，<C-s> 全选，<C-u> 取消全选
--    - 正常模式：<space> 切换选择，a 添加到选择，x 移除选择，<C-a> 全选，<C-u> 取消全选
--
-- 2. 批量操作：
--    - 选择多个项目后按 <Enter> 会在新标签页中打开所有选中的文件
--
-- 3. 查看选择状态：
--    选中的项目会高亮显示，可以通过以下命令查看选择了多少项目：
--    :lua local picker = require('telescope.actions.state').get_current_picker(vim.api.nvim_get_current_buf())
--    :lua print("已选择 " .. #picker:get_multi_selection() .. " 个项目")
--
-- 4. 重要提示：
--    - 不要使用 <C-m> 作为切换选择的快捷键，因为它在终端中等同于回车键
--    - 如果 <C-space> 在你的终端中不工作，可以尝试其他组合键如 <C-@>
--
-- 5. 自定义快捷键示例：
--    可以在你的 keymaps 配置中添加以下快捷键：
--    vim.keymap.set('n', '<leader>fm', function()
--        require('telescope.builtin').find_files({
--            attach_mappings = function(prompt_bufnr, map)
--                map('i', '<F2>', function()
--                    local picker = require('telescope.actions.state').get_current_picker(prompt_bufnr)
--                    local count = #picker:get_multi_selection()
--                    vim.notify("当前选择了 " .. count .. " 个文件", vim.log.levels.INFO)
--                end)
--                return true
--            end
--        })
--    end, { desc = 'Find files with multi-select test' })
