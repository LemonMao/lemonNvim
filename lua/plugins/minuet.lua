require('minuet').setup {
    -- Provider
    provider = 'gemini',
    -- provider = 'openai_fim_compatible',
    provider_options = {
        openai_fim_compatible = {
            end_point = 'https://api.deepseek.com/beta',
            model = 'deepseek-chat',
            stream = true,
            api_key = 'DEEPSEEK_API_KEY',
            name = 'deepseek',
            optional = {
                max_tokens = 256,
                top_p = 0.9,
            },
        },
        gemini = {
            model = 'gemini-2.5-flash-lite',
            stream = true,
            api_key = 'GEMINI_API_KEY',
            end_point = 'https://generativelanguage.googleapis.com/v1beta/models',
            optional = {
                generationConfig = {
                    maxOutputTokens = 256,
                    -- When using `gemini-2.5-flash`, it is recommended to entirely
                    -- disable thinking for faster completion retrieval.
                    thinkingConfig = {
                        thinkingBudget = 0,
                    },
                },
            },
            -- a list of functions to transform the endpoint, header, and request body
            transform = {},
        },
    },

    virtualtext = {
        -- Specify the filetypes to enable automatic virtual text completion,
        -- e.g., { 'python', 'lua' }. Note that you can still invoke manual
        -- completion even if the filetype is not on your auto_trigger_ft list.
        auto_trigger_ft = {},
        -- specify file types where automatic virtual text completion should be
        -- disabled. This option is useful when auto-completion is enabled for
        -- all file types i.e., when auto_trigger_ft = { '*' }
        auto_trigger_ignore_ft = {},
        keymap = {
            -- accept whole completion
            accept = nil,
            -- accept one line
            accept_line = nil,
            -- accept n lines (prompts for number)
            -- e.g. "A-z 2 CR" will accept 2 lines
            accept_n_lines = '<A-z>',
            -- Cycle to prev completion item, or manually invoke completion
            prev = nil,
            -- Cycle to next completion item, or manually invoke completion
            next = nil,
            dismiss = nil,
        },
        -- Whether show virtual text suggestion when the completion menu
        -- (nvim-cmp or blink-cmp) is visible.
        show_on_completion_menu = false,
    },
    -- the maximum total characters of the context before and after the cursor
    -- 16000 characters typically equate to approximately 4,000 tokens for LLMs.
    context_window = 10000,
    -- when the total characters exceed the context window, the ratio of
    -- context before cursor and after cursor, the larger the ratio the more
    -- context before cursor will be used. This option should be between 0 and
    -- 1, context_ratio = 0.75 means the ratio will be 3:1.
    context_ratio = 0.75,
    -- 请求状态的通知显示级别。
    -- false (禁用), "debug" (全开启), "verbose" (详细), "warn" (仅警告/错误), "error" (仅错误)
    notify = 'warn',
    -- 执行 HTTP 请求的命令，默认为 curl。
    curl_cmd = 'curl',
    -- 传递给 curl 的额外参数列表。
    curl_extra_args = {"-k"},
    -- 提示词中要求的补全建议数量。
    -- 对于 FIM 模型，这代表发送请求的次数。实际返回数量可能受 add_single_line_entry 影响。
    n_completions = 3,
}
