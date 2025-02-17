local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local extras = require "luasnip.extras"
local rep = extras.rep

vim.g.snip_author  = "Lemon Mao"
vim.g.snip_mail    = "lemon_mao@dell.com"
vim.g.snip_company = "Dell Inc."

require("luasnip.loaders.from_snipmate").lazy_load({ include = { "c", "cpp", "sh" } })
require("luasnip.loaders.from_snipmate").lazy_load({ path = { "~/.config/nvim/snippets" } })

ls.add_snippets("c", {
    -- s("fileg", {
    --     t({"#ifndef "}), i(1, "_`toupper(Filename('', 'UNTITLED'))`_H_"),
    --     t({"#define "}), rep(1),
    --     t({"", "", i(2), "", "#endif /* end of include guard: "}), rep(1), t({" */"})
    -- })
})
