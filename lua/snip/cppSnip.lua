local ls = require("luasnip")
local s = ls.snippet
local sn = ls.snippet_node
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local c = ls.choice_node
local d = ls.dynamic_node
local r = ls.restore_node
local extras = require "luasnip.extras"
local rep = extras.rep

-- in a cpp file: search cpp-, then c-, then all-snippets.
ls.filetype_extend("cpp", { "c" })

ls.add_snippets("cpp", {
    -- s("readfile", {
    --     -- Read File Into Vector
    --     t({"std::vector<char> v;", "if (FILE *", }), -- Line 1 & Line 2 start
    --     i(2, "fp"),
    --     t({" = fopen(", }),
    --     i(1, "\"filename\""),
    --     t({
    --         ", \"r\")) {",
    --         "    char buf[1024];",
    --         "    while (size_t len = fread(buf, 1, sizeof(buf), "
    --     }),
    --     i(2),
    --     t({
    --         "))",
    --         "        v.insert(v.end(), buf, buf + len);",
    --         "    fclose("
    --     }),
    --     i(2),
    --     t({");", "}"}),
    --     i(3)
    -- }),
    -- s({ trig = "class non-default", name = "class - non-copyable/moveable" }, {
    --     t("class "), i(1),
    --     t({ "", "{" }),
    --     t({ "", "\tpublic:" }),
    --     t({ "", "\t// constructor and destructor" }),
    --     t({ "", "\t" }), rep(1), t("();"),
    --     t({ "", "\t~" }), rep(1), t("() = default;"),
    --     t({ "", "\t// non-copyable and non-moveable" }),
    --     t({ "", "\t" }), rep(1), t("(const "), rep(1), t(" &) = delete;"),
    --     t({ "", "\t" }), rep(1), t("& operator=(const "), rep(1), t(" &) = delete;"),
    --     t({ "", "\t" }), rep(1), t("("), rep(1), t(" &&) = delete;"),
    --     t({ "", "\t" }), rep(1), t("& operator=("), rep(1), t(" &&) = delete;"),
    --     t({ "", "private:" }),
    --     t({ "", "};" }),
    -- }),
})
