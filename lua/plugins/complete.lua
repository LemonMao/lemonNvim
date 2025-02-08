local status, cmp = pcall(require, "cmp")
if not status then
    vim.notify("Not find plugin nvim-cmp")
    return
end

cmp.setup({
    snippet = {
        -- REQUIRED - you must specify a snippet engine
        expand = function(args)
            vim.fn["vsnip#anonymous"](args.body) -- For `vsnip` users.
            -- require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
        end,
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
                vsnip = 'snip',
                -- luasnip = 'snip',
                buffer = 'buf',
                path = 'path',
                codeium = 'LLM',
            }

            item.menu = menu_icon[entry.source.name]
            return item
        end,
    },
    mapping = require("keybindings").cmp(cmp),
    sources = cmp.config.sources(
        {
            { name = "codeium" },
            { name = 'nvim_lsp' },
            { name = 'vsnip' }, -- For vsnip users.
            -- { name = 'luasnip' }, -- For luasnip users.
        },
        {
            { name = 'buffer' }, { name = 'path' }, { name = 'cmdline' }
        }
    )
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
