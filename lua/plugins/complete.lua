local status, cmp = pcall(require, "cmp")
if not status then
    vim.notify("Not find plugin nvim-cmp")
    return
end

local minuet_action = require("minuet.virtualtext").action
local luasnipm = require("luasnip")


-- Track the current enabled status of nvim-cmp
local cmp_is_enabled = true

local kind_icons = {
    Text = "󰉿",
    Method = "󰆧",
    Function = "󰊕",
    Constructor = "",
    Field = "󰜢",
    Variable = "󰀫",
    Class = "󰠱",
    Interface = "",
    Module = "",
    Property = "󰜢",
    Unit = "",
    Value = "󰎠",
    Enum = "",
    Keyword = "󰌋",
    Snippet = "",
    Color = "󰏘",
    File = "󰈙",
    Reference = "󰈇",
    Folder = "󰉋",
    EnumMember = "",
    Constant = "󰏿",
    Struct = "󰙅",
    Event = "",
    Operator = "󰆕",
    TypeParameter = "󰅲",
}

cmp.setup({
    enabled = function()
        local disabled = false
        disabled = disabled or (vim.fn.reg_recording() ~= '')
        disabled = disabled or (vim.fn.reg_executing() ~= '')
        -- 调试：取消下面行的注释以在通知中显示缓冲区属性
        -- local buftype = vim.api.nvim_get_option_value('buftype', { buf = 0 })
        -- local filetype = vim.api.nvim_get_option_value('filetype', { buf = 0 })
        -- vim.notify(string.format("cmp enabled: buftype=%s, filetype=%s, disabled=%s", buftype, filetype, disabled), vim.log.levels.INFO)
        return not disabled
    end,
    snippet = {
        -- REQUIRED - you must specify a snippet engine
        expand = function(args)
            -- vim.fn["vsnip#anonymous"](args.body) -- For `vsnip` users.
            require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
        end,
    },
    completion = {
        keyword_length = 2,
    },
    window = {
        completion = cmp.config.window.bordered(),
        documentation = cmp.config.window.bordered(),
    },
    formatting = {
        fields = {'abbr', 'kind', 'menu', },
        format = function(entry, vim_item)
            -- Kind icons
            vim_item.kind = string.format('%s %s', kind_icons[vim_item.kind], vim_item.kind) -- This concatenates the icons with the name of the item kind
            -- Source
            vim_item.menu = ({
                luasnip = "[snip]",
                nvim_lsp = "[lsp]",
                buffer = "[buf]",
                path = '[path]',
                codeium = '[LLM]',
                latex_symbols = "[LaTeX]",
            })[entry.source.name]
            return vim_item
        end
    },
    mapping = {
--[[
   [    Default key mapping
   [    Insert mode:
   [    - `<Down>`: 选择下一个补全项（仅移动选中状态，不改变缓冲区文本）。
   [    - `<Up>`: 选择上一个补全项（仅移动选中状态，不改变缓冲区文本）。
   [    - `<C-n>`: 如果补全菜单已显示，则选择下一个补全项并将其内容插入到文本中；如果菜单未显示，则手动触发补全。
   [    - `<C-p>`: 如果补全菜单已显示，则选择上一个补全项并将其内容插入到文本中；如果菜单未显示，则手动触发补全。
   [    - `<C-y>`: 确认当前选中的补全项。如果当前没有选中的项（即只是高亮但未确认），则不会执行确认操作。
   [    - `<C-e>`: 中止补全，关闭菜单并恢复到触发补全前的原始文本状态。
   [
   [    Command mode:
   [    - `<C-z>`: 如果补全菜单已显示，则选择下一个补全项；如果菜单未显示，则手动触发补全。
   [    - `<Tab>`: 如果补全菜单已显示，则选择下一个补全项；如果菜单未显示，则手动触发补全。
   [    - `<S-Tab>`: 如果补全菜单已显示，则选择上一个补全项；如果菜单未显示，则手动触发补全。
   [    - `<C-n>`: 如果补全菜单已显示，则选择下一个补全项；如果菜单未显示，则执行默认行为（通常是浏览命令历史）。
   [    - `<C-p>`: 如果补全菜单已显示，则选择上一个补全项；如果菜单未显示，则执行默认行为（通常是浏览命令历史）。
   [    - `<C-e>`: 中止补全并关闭菜单。
   [    - `<C-y>`: 确认当前选中的补全项。如果当前没有选中的项，则不会执行确认操作。
   ]]

        -- ["<C-b>"] = cmp.mapping(cmp.mapping.scroll_docs(-4), {"s"}),
        -- ["<C-f>"] = cmp.mapping(cmp.mapping.scroll_docs(4), {"s"}),
        ['<C-n>'] = cmp.mapping({
            i = function(fallback)
                if cmp.visible() then
                    cmp.select_next_item()
                else
                    if minuet_action.is_visible() then
                        minuet_action.next()
                    else
                        cmp.complete()
                    end
                end
            end,
            c = function(fallback)
                if cmp.visible() then
                    cmp.select_next_item()
                else
                    if minuet_action.is_visible() then
                        minuet_action.next()
                    else
                        fallback()
                    end
                end
            end,
        }),
        ['<C-p>'] = cmp.mapping({
            i = function(fallback)
                if cmp.visible() then
                    cmp.select_prev_item()
                else
                    if minuet_action.is_visible() then
                        minuet_action.prev()
                    else
                        cmp.complete()
                    end
                end
            end,
            c = function(fallback)
                if cmp.visible() then
                    cmp.select_prev_item()
                else
                    if minuet_action.is_visible() then
                        minuet_action.prev()
                    else
                        fallback()
                    end
                end
            end,
        }),
        ["<CR>"] = cmp.mapping(function(fallback)
            if cmp.visible() and cmp.get_active_entry() then
                if luasnipm.expandable() then
                    luasnipm.expand()
                else
                    cmp.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = false })
                end
            else
                if minuet_action.is_visible() then
                    minuet_action.accept_n_lines()
                else
                    fallback()
                end
            end
        end, {"i", "s"}),

        -- LuaSnip Super Tab
        ["<Tab>"] = cmp.mapping(function(fallback)
            if luasnipm.locally_jumpable(1) then
                luasnipm.jump(1)
            elseif cmp.visible() then
                cmp.select_next_item()
            else
                if minuet_action.is_visible() then
                    -- accept whole LLM completion
                    minuet_action.accept()
                else
                    -- 使用 feedkeys 模拟原生 Tab 行为，绕过 nvim-cmp 在 NVIM 0.11 上的 fallback Bug
                    -- local termcode = vim.api.nvim_replace_termcodes("<Tab>", true, true, true)
                    -- vim.api.nvim_feedkeys(termcode, "n", true)
                    fallback()
                end
            end
        end, {"i", "s"}),

        ["<S-Tab>"] = cmp.mapping(function(fallback)
            if luasnipm.locally_jumpable(-1) then
                luasnipm.jump(-1)
            elseif cmp.visible() then
                cmp.select_prev_item()
            else
                -- 使用 feedkeys 模拟原生 Tab 行为，绕过 nvim-cmp 在 NVIM 0.11 上的 fallback Bug
                -- local termcode = vim.api.nvim_replace_termcodes("<Tab>", true, true, true)
                -- vim.api.nvim_feedkeys(termcode, "n", true)
                fallback()
            end
        end, {"i", "s"}),
    },
    sources = cmp.config.sources(
        {
            { name = 'luasnip' }, -- For luasnip users.
            { name = 'nvim_lsp' },
        },
        {
            { name = 'buffer' }, { name = 'path' }, { name = 'cmdline' }
        }
    )
})

-- Function to toggle nvim-cmp
local function toggle_cmp_status()
    if cmp_is_enabled then
        cmp.setup({ enabled = false })
        cmp_is_enabled = false
        vim.notify("nvim-cmp disabled", vim.log.levels.INFO, { title = "nvim-cmp" })
    else
        cmp.setup({ enabled = true })
        cmp_is_enabled = true
        vim.notify("nvim-cmp enabled", vim.log.levels.INFO, { title = "nvim-cmp" })
    end
end

-- Create a user command to toggle nvim-cmp
vim.api.nvim_create_user_command('CmpToggle', toggle_cmp_status, {
    desc = 'Toggle nvim-cmp completion',
})

-- Use buffer source for `/` and `?` (if you enabled `native_menu`, this won't work anymore).
cmp.setup.cmdline({ '/', '?' }, {
    mapping = cmp.mapping.preset.cmdline(),
    sources = {
        { name = 'buffer' }
    }
})

-- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
cmp.setup.cmdline(':', {
    mapping = cmp.mapping.preset.cmdline(),
    sources = cmp.config.sources({
        { name = 'path' }
    },
    {
        { name = 'cmdline' }
    }),
    matching = { disallow_symbol_nonprefix_matching = false }
})

local function debug_cmp_detailed()
    local buftype = vim.api.nvim_get_option_value('buftype', {buf=0})
    local filetype = vim.api.nvim_get_option_value('filetype', {buf=0})
    local disabled = (vim.fn.reg_recording() ~= '') or (vim.fn.reg_executing() ~= '')
    local enabled = not disabled
    vim.notify(string.format("cmp debug detailed: buftype=%s, filetype=%s, enabled=%s", buftype, filetype, enabled), vim.log.levels.INFO)
    local status, cmp = pcall(require, "cmp")
    if status then
        -- 尝试获取配置中的源
        local config = cmp.get_config()
        if config and config.sources then
            vim.notify(string.format("Global sources count: %d", #config.sources), vim.log.levels.INFO)
            for i, source in ipairs(config.sources) do
                vim.notify(string.format("Global source [%d]: %s", i, vim.inspect(source)), vim.log.levels.INFO)
            end
        else
            vim.notify("No global sources found in config", vim.log.levels.INFO)
        end
        -- 尝试获取当前缓冲区的源，通过 cmp.get_active_sources 如果存在的话
        local ok, active_sources = pcall(cmp.get_active_sources)
        if ok then
            vim.notify(string.format("Active sources count: %d", #active_sources), vim.log.levels.INFO)
            for _, source in ipairs(active_sources) do
                vim.notify(string.format("Active source: %s", source.name), vim.log.levels.INFO)
            end
        else
            vim.notify("Cannot get active sources (function not available)", vim.log.levels.INFO)
        end
        -- 尝试获取当前缓冲区的缓冲区特定配置
        local buf_config = cmp.get_buffer_config()
        if buf_config and buf_config.sources then
            vim.notify(string.format("Buffer-specific sources count: %d", #buf_config.sources), vim.log.levels.INFO)
            for i, source in ipairs(buf_config.sources) do
                vim.notify(string.format("Buffer source [%d]: %s", i, vim.inspect(source)), vim.log.levels.INFO)
            end
        end
    else
        vim.notify("cmp module not loaded", vim.log.levels.ERROR)
    end
end


vim.api.nvim_create_user_command('CmpDebugDetailed', debug_cmp_detailed, {
    desc = 'Detailed debug nvim-cmp sources and availability',
})

local function add_sources_to_current_buffer()
    local bufnr = vim.api.nvim_get_current_buf()
    local filetype = vim.api.nvim_get_option_value('filetype', { buf = bufnr })

    if filetype ~= 'AvanteInput' then
        vim.notify("当前缓冲区不是 AvanteInput，无需添加额外源", vim.log.levels.WARN)
        return
    end

    -- 获取当前的缓冲区配置
    local status, cmp = pcall(require, "cmp")
    if not status then
        vim.notify("无法加载 cmp 模块", vim.log.levels.ERROR)
        return
    end

    -- 尝试获取当前的源配置
    local current_sources = {}
    local ok, config = pcall(cmp.get_config)
    if ok and config and config.sources then
        -- 复制全局源
        for _, source in ipairs(config.sources) do
            table.insert(current_sources, source)
        end
    end

    -- 添加我们需要的额外源
    local extra_sources = {
        { name = 'luasnip' },
        { name = 'nvim_lsp' },
        { name = 'buffer' },
        { name = 'path' }
    }

    -- 合并源，避免重复
    for _, extra in ipairs(extra_sources) do
        local exists = false
        for _, current in ipairs(current_sources) do
            if current.name == extra.name then
                exists = true
                break
            end
        end
        if not exists then
            table.insert(current_sources, extra)
        end
    end

    -- 设置新的缓冲区配置
    cmp.setup.buffer({
        sources = current_sources
    })

    vim.notify(string.format("已为 AvanteInput 添加额外补全源，当前共 %d 个源", #current_sources), vim.log.levels.INFO)
end

-- 自动命令：当进入 AvanteInput 缓冲区时自动添加额外源
vim.api.nvim_create_autocmd('FileType', {
    pattern = 'AvanteInput',
    callback = function()
        -- 延迟执行，确保 Avante 插件先设置好它的源
        vim.defer_fn(function()
            add_sources_to_current_buffer()
        end, 100)
    end,
    desc = '为 AvanteInput 添加额外补全源'
})

-- 用户命令：手动触发添加额外源
vim.api.nvim_create_user_command('CmpAddExtraSources', add_sources_to_current_buffer, {
    desc = '为当前缓冲区添加额外的补全源'
})
