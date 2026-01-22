local status, cmp = pcall(require, "cmp")
if not status then
    vim.notify("Not find plugin nvim-cmp")
    return
end

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
        -- 在录制宏时, 在执行宏时, 在注释中禁用
        -- 在“提示符”缓冲区, disabled = disabled or (vim.api.nvim_get_option_value('buftype', { buf = 0 }) == 'prompt')
        disabled = disabled or (vim.fn.reg_recording() ~= '')
        disabled = disabled or (vim.fn.reg_executing() ~= '')
        -- disabled = disabled or require('cmp.config.context').in_treesitter_capture('comment')
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
                    cmp.complete()
                end
            end,
            c = function(fallback)
                if cmp.visible() then
                    cmp.select_next_item()
                else
                    fallback()
                end
            end,
        }),
        ['<C-p>'] = cmp.mapping({
            i = function(fallback)
                if cmp.visible() then
                    cmp.select_prev_item()
                else
                    cmp.complete()
                end
            end,
            c = function(fallback)
                if cmp.visible() then
                    cmp.select_prev_item()
                else
                    fallback()
                end
            end,
        }),
        ['<C-x>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
                cmp.abort()
                require('codeium.virtual_text').cycle_or_complete()
            else
                require('codeium.virtual_text').cycle_or_complete()
            end
        end),
        ["<CR>"] = cmp.mapping(function(fallback)
            if cmp.visible() and cmp.get_active_entry() then
                if luasnipm.expandable() then
                    luasnipm.expand()
                else
                    cmp.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = false })
                end
            else
                fallback()
            end
        end),

        -- LuaSnip Super Tab
        ["<Tab>"] = cmp.mapping(function(fallback)
            if luasnipm.locally_jumpable(1) then
                luasnipm.jump(1)
            elseif cmp.visible() then
                cmp.select_next_item()
            else
                -- 使用 feedkeys 模拟原生 Tab 行为，绕过 nvim-cmp 在 NVIM 0.11 上的 fallback Bug
                -- local termcode = vim.api.nvim_replace_termcodes("<Tab>", true, true, true)
                -- vim.api.nvim_feedkeys(termcode, "n", true)
                fallback()
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
    }, {
            { name = 'cmdline' }
        }),
    matching = { disallow_symbol_nonprefix_matching = false }
})
