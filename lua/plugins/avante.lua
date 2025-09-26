local avanteOpts = {}

avanteOpts.opts = {
    -- @alias avante.Mode "agentic" | "legacy"
    mode = "legacy",
    auto_suggestions_provider = "gemini_flash",
    -- claude = {
    --     endpoint = "https://api.anthropic.com",
    --     model = "claude-3-5-sonnet-20241022",
    --     temperature = 0,
    --     max_tokens = 4096,
    -- },
    -- provider = "deepseek",
    -- provider = "gemini_flash",
    provider = "gemini",
    providers = {
        gemini = {
            endpoint = "https://generativelanguage.googleapis.com/v1beta/models", -- The endpoint for the Gemini API.  Currently unused.
            model = "gemini-2.5-pro", -- The Gemini model to use (e.g., "gemini-2.0-flash").
            -- model = "gemini-2.0-flash-thinking-exp",
            -- model = "gemini-2.5-flash",
            disable_tools = false,
            extra_request_body = {
                max_tokens = 131072, -- The maximum number of tokens in the generated response.
                generationConfig = {
                    temperature = 0.25,
                },
            },
        },
        gemini_flash = {
            __inherited_from = "gemini",
            endpoint = "https://generativelanguage.googleapis.com/v1beta/models",
            model = "gemini-2.5-flash",
            disable_tools = false,
            extra_request_body = {
                max_tokens = 131072, -- 128k, maximum number of tokens in the generated response.
                generationConfig = {
                    temperature = 0.25,
                },
            },
        },
        deepseek_r = {
            __inherited_from = "openai",
            api_key_name = "DEEPSEEK_API_KEY",
            endpoint = "https://api.deepseek.com",
            -- model = "deepseek-chat",
            model = "deepseek-reasoner",
            timeout = 30000, -- timeout in milliseconds
            disable_tools = true,
            extra_request_body = {
                temperature = 0.25,
                max_tokens = 65536, -- 64k, maximum number of tokens in the generated response.
                max_completion_tokens = 65536, -- Increase this to include reasoning tokens (for reasoning models)
                reasoning_effort = "medium", -- low|medium|high, only used for reasoning models
            },
        },
        --[[
           [deepseek_v = {
           [    __inherited_from = "openai",
           [    api_key_name = "DEEPSEEK_API_KEY",
           [    endpoint = "https://api.deepseek.com",
           [    model = "deepseek-chat",
           [    -- model = "deepseek-reasoner",
           [    timeout = 30000, -- timeout in milliseconds
           [    temperature = 0.2, -- adjust if needed
           [    max_tokens = 8192,
           [    disable_tools = false,
           [},
           ]]
    },
    web_search_engine = {
        provider = "tavily",
        providers = {
            tavily = {
                api_key_name = "TAVILY_API_KEY",
                extra_request_body = {
                    include_answer = "basic",
                },
                format_response_body = function(body) return body.anwser, nil end,
            },
        },
    },

    behaviour = {
        auto_focus_sidebar = true,
        auto_suggestions = false, -- Experimental stage
        auto_suggestions_respect_ignore = false,
        auto_set_highlight_group = true,
        auto_set_keymaps = true,
        auto_apply_diff_after_generation = false,
        jump_result_buffer_on_finish = false,
        support_paste_from_clipboard = false,
        minimize_diff = true,
        enable_token_counting = true,
        use_cwd_as_project_root = true,
        enable_cursor_planning_mode = false,
    },
    ---Specify the special dual_boost mode
    ---1. enabled: Whether to enable dual_boost mode. Default to false.
    ---2. first_provider: The first provider to generate response. Default to "openai".
    ---3. second_provider: The second provider to generate response. Default to "claude".
    ---4. prompt: The prompt to generate response based on the two reference outputs.
    ---5. timeout: Timeout in milliseconds. Default to 60000.
    ---How it works:
    --- When dual_boost is enabled, avante will generate two responses from the first_provider and second_provider respectively. Then use the response from the first_provider as provider1_output and the response from the second_provider as provider2_output. Finally, avante will generate a response based on the prompt and the two reference outputs, with the default Provider as normal.
    ---Note: This is an experimental feature and may not work as expected.
    dual_boost = {
        enabled = false,
        first_provider = "gemini",
        second_provider = "deepseek_r",
        prompt = "Based on the two reference outputs below, generate a response that incorporates elements from both but reflects your own judgment and unique perspective. Do not provide any explanation, just give the response directly. Reference Output 1: [{{provider1_output}}], Reference Output 2: [{{provider2_output}}]",
        timeout = 60000, -- Timeout in milliseconds
    },
    mappings = {
        diff = {
            ours = "co",
            theirs = "ct",
            all_theirs = "ca",
            both = "cb",
            cursor = "cc",
            next = "]x",
            prev = "[x",
        },
        suggestion = {
            accept = "<M-l>",
            next = "<M-]>",
            prev = "<M-[>",
            dismiss = "<C-]>",
        },
        jump = {
            next = "]]",
            prev = "[[",
        },
        submit = {
            normal = "<CR>",
            insert = "<C-d>",
        },
        cancel = {
            normal = { "<C-c>", "<Esc>", "q" },
            insert = { "<C-c>" },
        },
        sidebar = {
            apply_all = "A",
            apply_cursor = "a",
            retry_user_request = "r",
            edit_user_request = "e",
            switch_windows = "<Tab>",
            reverse_switch_windows = "<S-Tab>",
            remove_file = "d",
            add_file = "@",
            close = { "<Esc>", "q" },
            close_from_input = nil, -- e.g., { normal = "<Esc>", insert = "<C-d>" }
        },
    },
    -- ask = "<leader>aa",
    -- edit = "<leader>ae",
    -- refresh = "<leader>ar",
    -- focus = "<leader>af",
    -- toggle = {
    --   default = "<leader>at",
    --   debug = "<leader>ad",
    --   hint = "<leader>ah",
    --   suggestion = "<leader>as",
    --   repomap = "<leader>aR",
    -- },

    windows = {
        -- @type "right" | "left" | "top" | "bottom"
        position = "right", -- the position of the sidebar
        wrap = true, -- similar to vim.o.wrap
        width = 55, -- default % based on available width
        height = 70,
        sidebar_header = {
            enabled = true, -- true, false to enable/disable the header
            align = "center", -- left, center, right for title
            rounded = true,
        },
        input = {
            prefix = "> ",
            height = 10, -- Height of the input window in vertical layout
        },
        edit = {
            border = "rounded",
            start_insert = false, -- Start insert mode when opening the edit window
        },
        ask = {
            floating = false, -- Open the 'AvanteAsk' prompt in a floating window
            start_insert = false, -- Start insert mode when opening the ask window
            border = "rounded",
            ---@type "ours" | "theirs"
            focus_on_apply = "theirs", -- which diff to focus after applying
        },
    },
    highlights = {
        -- @type AvanteConflictHighlights
        diff = {
            current = "DiffText",
            incoming = "DiffAdd",
        },
    },
    -- @class AvanteConflictUserConfig
    diff = {
        autojump = true,
        -- @type string | fun(): any
        list_opener = "copen",
        --- Override the 'timeoutlen' setting while hovering over a diff (see :help timeoutlen).
        --- Helps to avoid entering operator-pending mode with diff mappings starting with `c`.
        --- Disable by setting to -1.
        override_timeoutlen = 500,
    },
    suggestion = {
        -- 去抖（debounce）和节流（throttle）控制建议频率
        debounce = 800,
        throttle = 800,
    },
    -- @class AvanteHintsConfig
    hints = {
        -- display the key map in right place
        enabled = false,
    },
    tokenizer = "tiktoken",
    rag_service = {
        enabled = false, -- Enables the rag service, requires OPENAI_API_KEY to be set
        provider = "openai", -- The provider to use for RAG service. eg: openai or ollama
        llm_model = "", -- The LLM model to use for RAG service
        embed_model = "", -- The embedding model to use for RAG service
        endpoint = "https://api.openai.com/v1", -- The API endpoint for RAG service
    },

    -- @class AvanteRepoMapConfig
    repo_map = {
        ignore_patterns = { "%.git", "%.worktree", "__pycache__", "node_modules" }, -- ignore files matching these
        negate_patterns = {}, -- negate ignore files matching these.
    },
    selector = {
        -- @alias avante.SelectorProvider "native" | "fzf_lua" | "mini_pick" | "snacks" | "telescope" | fun(selector: avante.ui.Selector): nil
        provider = "telescope",
        exclude_auto_select = { "NvimTree" },
    },
    shortcuts = {
        {
            name = "refactor",
            description = "Refactor code with best practices",
            details = "Automatically refactor code to improve readability, maintainability, and follow best practices while preserving functionality",
            prompt = "Please refactor the selected code following best practices, improving readability and maintainability while preserving functionality."
        },
        {
            name = "explain_code",
            description = "Explain the code",
            details = "Explain the code",
            prompt = "Work as a professional programmer to explain the selected code. " ..
                    "First, provide a detailed, code-level description/explaination, similar to adding comments to code. " ..
                    "At last provide a summary description/explaination. " ..
                    "Respond in Chinese."
        },
        {
            name = "explain_example",
            description = "Explain the code with example",
            details = "Explain the code with example",
            prompt = "Work as a professional programmer to explain the selected code. " ..
                    "First, provide a detailed, code-level description/explaination, similar to adding comments to code. " ..
                    "At last provide a summary description/explaination. " ..
                    "Always respond in Chinese. Give examples to illustrate the concept."
        },
        {
            name = "explain_concept",
            description = "Explain the concept of module",
            details = "Explain the concept of module",
            prompt = "Work as a professional software architect to explain the concept of module. I want to know: \n" ..
                    "- What is the module used for? \n" ..
                    "- Why design that? \n" ..
                    "- What's the important components in this module? How to use them?\n" ..
                    "  You should list the strcutre and comment for the important member variable.\n" ..
                    "- How does it work with other modules? \n" ..
                    "- Use an example to illustrate the workflow of it. \n" ..
                    "Always respond in Chinese. The module is: "
        },
        {
            name = "complete",
            description = "Complete the code",
            details = "Complete the code with readability, maintainability, and follow best practices while preserving functionality",
            prompt = "Please complete the selected code following best practices, improving readability and maintainability while preserving functionality. Answer in Chinse."
        },
        {
            name = "chinese",
            description = "Answer in Chinse",
            details = "Answer in Chinse",
            prompt = "Always respond in Chinese in all chat."
        },
        {
            name = "example",
            description = "Give examples to illustrate the concept",
            details = "Give examples to illustrate the concept",
            prompt = "Give examples to illustrate the concept. Answer in Chinse."
        },
        -- Add more custom shortcuts...
    }
}

---------------------------------------------
---------         Usage          ------------
---------------------------------------------
-- 1.  **``, `@file`, `@quickfix`, `@diagnostics` 的用法：**
--
-- 这些都是在 AvanteInput 输入框中使用的“提及 (mentions)”，用于向 AI 提供额外的上下文信息，以便 AI 更好地理解你的问题和代码。
--
-- *   **`` (隐式提及 - Implicit Mention):  选中的代码块**
--
--     当你使用 `AvanteAsk` 或 `AvanteEdit` 命令时，如果你在编辑器中选中了代码块（通过 Visual 模式），Avante 会自动将选中的代码块作为上下文发送给 AI。这是一种隐式提及，不需要你手动输入任何特殊符号。
--
--     **示例：**
--
--     假设你在 Lua 文件中选中了一段函数代码，然后使用 `:AvanteAsk "解释这段函数的作用"`，AI 会自动理解你的问题是关于你选中的那段代码的。
--
-- *   **`@file`:  添加选中的文件到上下文**
--
--     在 AvanteInput 输入框中输入 `@file`，可以打开文件选择器。你可以选择一个或多个文件，Avante 会将这些文件的内容添加到 AI 的上下文信息中。这使得 AI 可以理解项目中的其他文件，从而提供更全面的代码建议。
--
--     **示例：**
--
--     在 AvanteInput 输入框中输入 `@file`，然后选择 `lua/avante/config.lua` 和 `lua/avante/api.lua` 两个文件。之后你提问 `:AvanteAsk "如何修改配置以支持新的 Provider?"`，AI 在回答时会考虑到 `config.lua` 和 `api.lua` 的内容。
--
-- *   **`@quickfix`: 添加 Quickfix 列表中的文件到上下文**
--
--     在 AvanteInput 输入框中输入 `@quickfix`，Avante 会将当前 Quickfix 列表中的所有文件添加到 AI 的上下文信息中。这在你处理代码错误或警告列表时非常有用，可以让 AI 了解整个问题域。
--
--     **示例：**
--
--     假设你使用 `:checkhealth` 或其他工具生成了一个 Quickfix 列表，其中包含多个错误文件。在 AvanteInput 输入框中输入 `@quickfix`，然后提问 `:AvanteAsk "如何修复这些错误?"`，AI 会考虑到 Quickfix 列表中的所有文件，帮助你分析和解决问题。
--
-- *   **`@diagnostics`:  包含诊断信息到上下文中**
--
--     在 AvanteInput 输入框中输入 `@diagnostics`，Avante 会将当前缓冲区（或选定代码块）的诊断信息（例如，来自 LSP 的错误、警告等）添加到 AI 的上下文中。这能帮助 AI 理解代码中存在的问题，并提供更精确的修复建议。
--
--     **示例：**
--
--     假设你的代码中存在一些 TypeScript 编译错误。在 AvanteInput 输入框中输入 `@diagnostics`，然后提问 `:AvanteAsk "如何修复这些 TypeScript 错误?"`，AI 在回答时会考虑到代码的诊断信息，给出更具针对性的修复建议。
--
-- 2.  **`/` 命令的用法，例如 `/lines`：**
--
-- `/` 命令是在 AvanteInput 输入框中使用的特殊命令，用于控制 Avante 侧边栏的行为和功能。
--
-- *   **`/lines <start>-<end> <question>`:  针对特定代码行提问**
--
--     `/lines` 命令允许你指定代码的行范围，并针对这些行提出问题。这在你想要 AI 专注于代码的特定部分时非常有用。
--
--     **示例：**
--
--     在 AvanteInput 输入框中输入 `/lines 10-20 如何优化这段循环的性能?`，Avante 会将你的问题限定在当前文件的第 10 行到第 20 行代码范围内，并向 AI 提问关于这段代码性能优化的问题。
--
--     **其他常用的 `/` 命令 (基于代码实现，但 README.md 中未完全列出，以下列出代码中实现的命令):**
--
--     *   `/help`: 显示帮助信息，列出所有可用的 `/` 命令及其描述。
--     *   `/clear`: 清空聊天历史记录。
--     *   `/reset`: 重置 AI 的记忆 (memory)。
--
-- *   Use `AvanteAsk` when you have a specific question about your code or need targeted code suggestions.
-- *   Use `AvanteEdit` when you want the AI to modify a specific block of code you've selected.
-- *   Use `AvanteChat` for general discussions and exploration of your codebase with the AI.

return avanteOpts
