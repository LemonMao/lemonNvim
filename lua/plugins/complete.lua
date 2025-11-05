local status, cmp = pcall(require, "cmp")
if not status then
    vim.notify("Not find plugin nvim-cmp")
    return
end

local luasnipm = require("luasnip")

-- Track the current enabled status of nvim-cmp
local cmp_is_enabled = true

cmp.setup({
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
        format = function(entry, item)
            local menu_icon = {
                nvim_lsp = 'lsp',
                -- vsnip = 'snip',
                luasnip = 'snip',
                buffer = 'buf',
                path = 'path',
                codeium = 'LLM',
            }

            item.menu = menu_icon[entry.source.name]
            return item
        end,
    },
    mapping = require("keybindings").cmp(cmp, luasnipm),
    sources = cmp.config.sources(
        {
            { name = "codeium" },
            { name = 'nvim_lsp' },
            -- { name = 'vsnip' }, -- For vsnip users.
            { name = 'luasnip' }, -- For luasnip users.
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
