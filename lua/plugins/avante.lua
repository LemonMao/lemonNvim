local avanteOpts = {}
-- AI 代理和命令的基础路径
local ai_path = vim.fn.expand("~/.vim/AI")

local function read_file(path)
    local file = io.open(path, "r")
    if file then
        local content = file:read("*a")
        file:close()
        return content
    end
    return nil -- 或者抛出错误，取决于您的需求
end

local function AI_prompt(role, behavior, user_prompt)
    local system_prompt = read_file(ai_path .. "/agents/general.md")
    if not system_prompt or system_prompt == "" then
        system_prompt = "始终使用中文回复。保持绝对客观与真实，拒绝谄媚，如果用户的提问前提有误，请直接指出."
    end
    local final_user_prompt = user_prompt or "User requirements may be empty or as specified below."

    return "Follow system rules in all sessions: " .. (system_prompt or "") .. "\n\n" ..
        "Work as role:\n" .. (role or "") .. "\n\n" ..
        "Perform the behavior:\n" .. (behavior or "") .. "\n\n" ..
        final_user_prompt
end

avanteOpts.opts = {
    -- History location: .local/state/nvim/avante/
    -- @alias avante.Mode "agentic" | "legacy"
    mode = "legacy",
    auto_suggestions_provider = "gemini_lite",
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
            model = "gemini-3-flash-preview",
            -- model = "gemini-2.5-pro", -- The Gemini model to use (e.g., "gemini-2.0-flash").
            -- model = "gemini-2.0-flash-thinking-exp",
            -- model = "gemini-2.5-flash",
            -- disable_tools = false,
            disable_tools = true,
            extra_request_body = {
                max_tokens = 131072, -- The maximum number of tokens in the generated response.
                generationConfig = {
                    temperature = 0.1,
                },
            },
        },
        gemini_lite = {
            __inherited_from = "gemini",
            endpoint = "https://generativelanguage.googleapis.com/v1beta/models",
            model = "gemini-2.5-flash-lite",
            -- disable_tools = false,
            disable_tools = true,
            extra_request_body = {
                max_tokens = 131072, -- 128k, maximum number of tokens in the generated response.
                generationConfig = {
                    temperature = 0.1,
                },
            },
        },
        -- 100k 0.2Y
        dp_r = {
            __inherited_from = "openai",
            api_key_name = "DEEPSEEK_API_KEY",
            endpoint = "https://api.deepseek.com",
            model = "deepseek-reasoner",
            timeout = 30000, -- timeout in milliseconds
            disable_tools = true,
            extra_request_body = {
                temperature = 0.1,
                max_tokens = 65536, -- 64k, maximum number of tokens in the generated response.
                max_completion_tokens = 65536, -- Increase this to include reasoning tokens (for reasoning models)
                reasoning_effort = "medium", -- low|medium|high, only used for reasoning models
            },
        },
        dp_c = {
            __inherited_from = "openai",
            api_key_name = "DEEPSEEK_API_KEY",
            endpoint = "https://api.deepseek.com",
            model = "deepseek-chat",
            timeout = 30000, -- timeout in milliseconds
            disable_tools = true,
        },
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
        width = 60, -- default % based on available width
        height = 70,
        sidebar_header = {
            enabled = true, -- true, false to enable/disable the header
            align = "center", -- left, center, right for title
            rounded = true,
        },
        input = {
            prefix = "> ",
            height = 15, -- Height of the input window in vertical layout
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
    system_prompt = "YYYY",
    shortcuts = {
        -- Roles
        {
            name = "system_prompt",
            description = "Apply system prompt for all sessions",
            details = "Apply system prompt for all sessions",
            prompt = (function()
                local prompt = read_file(ai_path .. "/agents/general.md")
                if not prompt or prompt == "" then
                    prompt = "始终使用中文回复。保持绝对客观与真实，拒绝谄媚，如果用户的提问前提有误，请直接指出"
                end
                return prompt
            end)()
        },
        {
            name = "role_cpp",
            description = "Work as a professional CPP language programmer",
            details = "Work as a professional CPP language programmer",
            prompt = (function()
                local content = read_file(ai_path .. "/agents/cpp_pro.md")
                return "Work as a professional CPP programmer as below." .. content .. "\n"
            end)()
        },
        {
            name = "role_c",
            description = "Work as a professional C language programmer",
            details = "Work as a professional C programmer",
            prompt = (function()
                local content = read_file(ai_path .. "/agents/c_pro.md")
                return "Work as a professional C language programmer as below." .. content .. "\n"
            end)()
        },
        {
            name = "role_python",
            description = "Work as a professional Python language programmer",
            details = "Work as a professional Python programmer",
            prompt = (function()
                local content = read_file(ai_path .. "/agents/python_pro.md")
                return "Work as a professional Python language programmer as below." .. content .. "\n"
            end)()
        },
        {
            name = "role_analyzer",
            description = "Work as a professional analyzer",
            details = "Work as a professional analyzer",
            prompt = (function()
                local content = read_file(ai_path .. "/agents/analyzer.md")
                return "Work as a professional analyzer as below." .. content .. "\n"
            end)()
        },
        {
            name = "role_docarchitect",
            description = "Work as a professional doc architect",
            details = "Work as a professional doc architect",
            prompt = (function()
                local content = read_file(ai_path .. "/agents/doc_architect.md")
                return "Work as a professional doc architect as below." .. content .. "\n"
            end)()
        },
        {
            name = "role_reviewer",
            description = "Work as a professional reviewer",
            details = "Work as a professional reviewer",
            prompt = (function()
                local content = read_file(ai_path .. "/agents/reviewer.md")
                return "Work as a professional reviewer as below." .. content .. "\n"
            end)()
        },
        -- Code
        {
            name = "modify_code",
            description = "Modify or implement features with requirements",
            details = "Modify selected code or implement features across files",
            prompt = (function()
                local role = read_file(ai_path .. "/agents/developer.md")
                local behavior = "1. If code is selected, focus on modifying or completing that specific block. If no code is selected, implement the requested feature by modifying all relevant files in the context.\n" ..
                "2. You must strictly provide the response in the following format:\n" ..
                "## code change\n" ..
                "[The modified or new code. Use necessary in-line English comments.]\n" ..
                "## explaination\n" ..
                "[A detail summary of the changes, benefits, and potential trade-offs.]\n" ..
                "3. When implementing feature, if user doesn't provide requirements. Ask for it." ..
                "4. Ensure the code follows best practices and the explanation is concise."
                return AI_prompt(role, behavior)
            end)()
        },
        {
            name = "explain_code",
            description = "Explain the code with requirements",
            details = "Explain the code with requirements",
            prompt = (function()
                local role = read_file(ai_path .. "/agents/doc_architect.md")
                local behavior = "1. Explan the selected code as following output:\n" ..
                    "## Summary\n" ..
                    "[Provide a detail description/explaination of 'What is it? What is it used for?]\n" ..
                    "## Code explain\n" ..
                    "[Provide detailed, code-level explaination, similar to in-line code comments for the selected code]\n" ..
                    "## Example\n" ..
                    "[Use an example to illustrate the workflow of it or how to use it]\n" ..
                    "2. If user doesn't provide the selected code, ask for it.\n"
                return AI_prompt(role, behavior)
            end)()
        },
        {
            name = "review_code",
            description = "Review the code with requirements",
            details = "Review the code with requirements",
            prompt = (function()
                local role = read_file(ai_path .. "/agents/reviewer.md")
                local behavior = "1. If user provides the selected code, just review this part code don't touch others\n" ..
                    "2. If user doesn't provide the selected code, review all the files\n"
                return AI_prompt(role, behavior)
            end)()
        },
        {
            name = "plan_feature",
            description = "Make plan how to implement the feature with requirements",
            details = "Make plan how to implement the feature with requirements",
            prompt = (function()
                local role = read_file(ai_path .. "/agents/doc_architect.md")
                local behavior = read_file(ai_path .. "/commands/plan_feature.md")
                return AI_prompt(role, behavior)
            end)()
        },
        -- common
        {
            name = "explain_simple",
            description = "Explain the target/question simply",
            details = "Explain the target simply",
            prompt = (function()
                local role = "You're a professional software engineer."
                local behavior = "1. Explan the target/question as following output:\n" ..
                    "## What's it?\n" ..
                    "[Provide a detail description/explaination of 'What is it? What is it used for?]\n" ..
                    "## Example\n" ..
                    "[Use an example to illustrate the workflow of it or how to use it.]\n" ..
                    "## Important components\n" ..
                    "[List important data structures and functions and comment for what they used for.]\n" ..
                    "2. Use the selected code as the target. If no selected code, user should provide one. If user doesn't provide target, ask for it."
                local user_prompt = "The target/question is: "
                return AI_prompt(role, behavior, user_prompt)
            end)()
        },
        {
            name = "explain_detail",
            description = "Explain the target/question detaily",
            details = "Explain the target detaily",
            prompt = (function()
                local role = "You're a professional software engineer."
                local behavior = "1. Explan the target/question as following output:\n" ..
                    "## What's it?\n" ..
                    "[Provide a detail description/explaination of 'What is it? What is it used for?]\n" ..
                    "## Example\n" ..
                    "[Use an example to illustrate the workflow of it or how to use it.]\n" ..
                    "## Important components\n" ..
                    "[What's the important components? How to use them?]\n" ..
                    "[List important data structures and functions and comment for what they used for.]\n" ..
                    "## Why design that?\n" ..
                    "[benefits, trade-offs, pros and cons, ...]\n" ..
                    "## Intergration\n" ..
                    "[How does it work with other modules?]\n" ..
                    "2. Use the selected code as the target. If no selected code, user should provide one. If user doesn't provide target, ask for it."
                local user_prompt = "The target/question is: "
                return AI_prompt(role, behavior, user_prompt)
            end)()
        },
        {
            name = "analyze_issue",
            description = "Analyze rootcause with the issue",
            details = "Analyze rootcause with the issue",
            prompt = (function()
                local role = read_file(ai_path .. "/agents/analyzer.md")
                local behavior = "1. Analyze the rootcause with the provided issue and logs.\n" ..
                    "2. Provide the possible solution.\n" ..
                    "3. If you cannot find the rootcause. Image one situation will cause it. You should tag it as just a guess.\n" ..
                    "4. Output format:\n" ..
                    "## Analysis\n" ..
                    "[Multiple Analysis results]\n" ..
                    "## Code change\n" ..
                    "[Code change of the most possilbe solution]\n"
                local user_prompt = "The issue is:\n"
                return AI_prompt(role, behavior, user_prompt)
            end)()
        },
        {
            name = "chinese",
            description = "Answer in Chinse",
            details = "Answer in Chinse",
            prompt = "Always respond in Chinese in all chat."
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

require("avante").setup(avanteOpts.opts)
-- Doesn't work know, maybe work in future
--[[
   [ require("avante.config").override({
   [     system_prompt = (function()
   [         local prompt = read_file(ai_path .. "/agents/general.md")
   [         if not prompt or prompt == "" then
   [             prompt = "始终使用中文回复。保持绝对客观与真实，拒绝谄媚，如果用户的提问前提有误，请直接指出"
   [         end
   [         return prompt
   [     end)()
   [ })
   ]]
return avanteOpts
