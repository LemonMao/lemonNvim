-- 为 log 文件类型启用 mini.hipatterns 高亮
vim.b.minihipatterns_config = {
    highlighters = {
        pass = {
            pattern = {
                "%f[%w]()PASS()%f[%W]",
                "%f[%w]()pass()%f[%W]",
            },
            group = "MiniHipatternsTodo",
        },
        fail = {
            pattern = {
                "%f[%w]()fail()%f[%W]",
                "%f[%w]()FAIL()%f[%W]",
                "%f[%w]()failure()%f[%W]",
                "%f[%w]()FAILURE()%f[%W]",
                "%f[%w]()failed()%f[%W]",
                "%f[%w]()error()%f[%W]",
                "%f[%w]()ERROR()%f[%W]",
                "%f[%w]()err()%f[%W]",
                "%f[%w]()ERR()%f[%W]",
            },
            group = "MiniHipatternsFixme",
        },
        warn = {
            pattern = {
                "%f[%w]()warn()%f[%W]",
                "%f[%w]()WARN()%f[%W]",
                "%f[%w]()warning()%f[%W]",
                "%f[%w]()WARNING()%f[%W]",
            },
            group = "MiniHipatternsHack",
        },

        -- Highlight hex color strings (`#rrggbb`) using that color
        hex_color = require("mini.hipatterns").gen_highlighter.hex_color(),
    },
}
