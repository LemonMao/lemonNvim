-- External functions statement
local utils = require("utils")
local ai_path = utils.ai_path

-- ########################
-- CodeCompanion SetUp
-- ########################
require("codecompanion").setup({
    adapters = {
        http = {
            gemini = function()
                return require("codecompanion.adapters").extend("gemini", {
                    schema = {
                        temperature = {
                            default = 0.1
                        },
                        top_p = {
                            default = 0.1
                        },
                        max_tokens = {
                            default = 64*1024,
                        },
                        reasoning_effort = {
                            default = "medium",
                        },
                    },
                })
            end,
            deepseek = function()
                return require("codecompanion.adapters").extend("deepseek", {
                    schema = {
                        model = {
                            default = "deepseek-chat",
                        },
                        temperature = {
                            default = 0.1
                        },
                        top_p = {
                            default = 0.1
                        },
                        max_tokens = {
                            default = 8*1024,
                        },
                        reasoning_effort = {
                            default = "medium",
                        },
                    },
                })
            end,
            opts = {
                show_model_choices = true,
                show_presets = false,
                allow_insecure = true,
            },
        },
    },
    interactions = {
        chat = {
            adapter = {
                name = "gemini",
                model = "gemini-3-flash-preview",
                -- model = "gemini-2.5-flash-lite",
            },
            roles = {
                llm = function(adapter)
                    return "CodeCompanion (" .. adapter.schema.model.default .. ")"
                end,
                user = "Lemon",
            },
            slash_commands = {
                ["file"] = {
                    keymaps = {
                        modes = {
                            n = { "sf"},
                        },
                    },
                },
                ["buffer"] = {
                    keymaps = {
                        modes = {
                            n = { "sb"},
                        },
                    },
                },
                ["rules"] = {
                    keymaps = {
                        modes = {
                            n = { "sr"},
                        },
                    },
                },
                ["git_files"] = {
                    description = "List git files",
                    callback = function(chat)
                        local handle = io.popen("git ls-files")
                        if handle ~= nil then
                            local result = handle:read("*a")
                            handle:close()
                            chat:add_context({ role = "user", content = result }, "git", "<git_files>")
                        else
                            return vim.notify("No git files available", vim.log.levels.INFO, { title = "CodeCompanion" })
                        end
                    end,
                    opts = {
                        contains_code = false,
                    },
                    keymaps = {
                        modes = {
                            n = { "sg"},
                        },
                    },
                },
                ["apply"] = {
                    description = "Apply the code change to current buffer",
                    callback = function(chat)
                        vim.api.nvim_put({ "Use @{insert_edit_into_file} to apply the change to #{buffer}.Don't explain. Just tell you're done or not." }, "c", true, true)
                    end,
                    opts = {
                        contains_code = false,
                    },
                },
            },
            keymaps = {
                completion = {
                    modes = { i = "<C-g>" },
                    index = 1,
                    callback = "keymaps.completion",
                    description = "[Chat] Completion menu",
                },
                send = {
                    modes = {
                        n = { "<CR>" },
                        i = "<C-d>",
                    },
                    callback = function(chat)
                        vim.cmd("stopinsert")
                        chat:submit()
                        chat:add_buf_message({ role = "llm", content = "" })
                    end,
                    index = 1,
                    description = "Send",
                },
            },
            opts = {
                system_prompt = utils.read_file(utils.AI_ROLES.ASSISTANT)

                -- system_prompt = "My system prompt"
            }

        },
        inline = {
            adapter = {
                name = "gemini",
                -- model = "gemini-3-flash-preview",
                model = "gemini-2.5-flash-lite",
            },
            keymaps = {
                accept_change = {
                    modes = { n = "ca" }, -- Remember this as DiffAccept
                },
                reject_change = {
                    modes = { n = "cr" }, -- Remember this as DiffReject
                },
                always_accept = {
                    modes = { n = "cy" }, -- Remember this as DiffYolo
                },
            },
        },
        cmd = {
            adapter = {
                name = "gemini",
                -- model = "gemini-3-flash-preview",
                model = "gemini-2.5-flash-lite",
            },
        },
        background = {
            adapter = {
                name = "gemini",
                -- model = "gemini-3-flash-preview",
                model = "gemini-2.5-flash-lite",
            },
        },
    },
    display = {
        action_palette = {
            opts = {
                show_preset_prompts = false
            }
        },
        diff = {
            enabled = true,
            provider = inline, -- inline|split|mini_diff
            provider_opts = {
                inline = {
                    layout = "buffer", -- float|buffer - Where to display the diff
                    opts = {
                        context_lines = 3, -- Number of context lines in hunks
                        dim = 25, -- Background dim level for floating diff (0-100, [100 full transparent], only applies when layout = "float")
                        full_width_removed = true, -- Make removed lines span full width
                        show_keymap_hints = true, -- Show "gda: accept | gdr: reject" hints above diff
                        show_removed = true, -- Show removed lines as virtual text
                    },
                },
            },
        },
    },
    opts = {
        log_level = "DEBUG",
        language = "Chinese", -- The language used for LLM responses
    },
    rules = {
        role_cpp = {
            description = "A professional CPP language expert",
            files = {
                utils.AI_ROLES.CPP_PRO,
            },
        },
        role_c = {
            description = "A professional C language expert",
            files = {
                utils.AI_ROLES.C_PRO,
            },
        },
        role_python = {
            description = "A professional Python language expert",
            files = {
                utils.AI_ROLES.PYTHON_PRO,
            },
        },
        role_analyzer = {
            description = "A professional analyzer",
            files = {
                utils.AI_ROLES.ANALYZER,
            },
        },
        role_architect = {
            description = "A professional doc architect",
            files = {
                utils.AI_ROLES.ARCHITECT,
            },
        },
        role_reviewer = {
            description = "A professional reviewer",
            files = {
                utils.AI_ROLES.REVIEWER,
            },
        },
    },

    prompt_library = {
        -- Use `:CodeCompanionActions refresh` to apply the new added prompt
        --[[
           [ markdown = {
           [     dirs = {
           [         "~/.config/nvim/AI/prompts",
           [     },
           [ },
           ]]
        ["Explain code"] = {
            interaction = "chat",
            description = "Explain the code",
            opts = {
                alias = "explain_code",
                auto_submit = false,
                modes = { "v", "n"},
                placement = "new",
                ignore_system_prompt = false,
                stop_context_insertion = true,
                is_slash_cmd = true,
                --[[
                -- intro_message = "Explain the code with requirements",
                   [is_workflow = false,
                   [ pre_hook = nil,
                   [ rules = nil,
                   [ stop_context_insertion = nil,
                   [ user_prompt = nil,
                   ]]
            },
            context = {
                {
                    type = "file",
                    path = {
                        utils.AI_ROLES.ARCHITECT,
                    },
                },
            },

            prompts = {
                {
                    role = "user",
                    content = function(context)
                        local behavior = "1. Explan the selected code as following output:\n" ..
                        "### Summary\n" ..
                        "[Provide a detail description/explaination of 'What is it? What is it used for?]\n" ..
                        "### Code explain\n" ..
                        "[Provide detailed, code-level explaination, similar to in-line code comments for the selected code]\n" ..
                        "### Example\n" ..
                        "[Use an example to illustrate the workflow of it or how to use it]\n" ..
                        "2. If user doesn't provide the selected code, ask for it.\n"

                        if context.is_visual then
                            local selected_code = utils.wrap_code_with_md(context.code, context.filetype)
                            behavior = behavior .. "3. The selected code of #{buffer} is:\n" .. selected_code .. "\n"
                        else
                            behavior = behavior .. "3. The current file is #{buffer}\n"
                        end

                        return behavior
                    end,
                },
            },
        },
        ["Explain target"] = {
            interaction = "chat",
            description = "Explain the target/question in target",
            opts = {
                alias = "explain_target",
                auto_submit = false,
                modes = { "v", "n" },
                placement = "new",
                ignore_system_prompt = false,
                stop_context_insertion = true,
                is_slash_cmd = true,
            },
            context = {
                {
                    type = "file",
                    path = {
                        utils.AI_ROLES.ARCHITECT,
                    },
                },
            },

            prompts = {
                {
                    role = "user",
                    content = function(context)
                        local behavior = "1. Explan the target/question as following output:\n" ..
                            "### What's it?\n" ..
                            "[Provide a detail description/explaination of 'What is it? What is it used for?]\n" ..
                            "### Example\n" ..
                            "[Use an example to illustrate the workflow of it or how to use it.]\n" ..
                            "### Important components\n" ..
                            "[What's the important components? How to use them?]\n" ..
                            "[List important data structures and functions and comment for what they used for.]\n" ..
                            "### Why design that?\n" ..
                            "[benefits, trade-offs, pros and cons, ...]\n" ..
                            "### Intergration\n" ..
                            "[How does it work with other modules?]\n" ..
                            "2. Use the selected code as the target. If no selected code, user should provide one. If user doesn't provide target, ask for it.\n"

                        if context.is_visual then
                            local selected_code = utils.wrap_code_with_md(context.code, context.filetype)
                            behavior = behavior .. "3. The selected code of #{buffer} is:\n" .. selected_code .. "\n"
                        else
                            behavior = behavior .. "3. The current file is #{buffer}\n"
                        end

                        return behavior
                    end,
                },
            },
        },
        ["Develop code"] = {
            interaction = "chat",
            description = "Modify code or implement features",
            opts = {
                alias = "develop_code",
                auto_submit = false,
                modes = { "v", "n" },
                placement = "new",
                ignore_system_prompt = false,
                stop_context_insertion = true,
                is_slash_cmd = true,
            },
            context = {
                {
                    type = "file",
                    path = {
                        utils.AI_ROLES.DEVELOPER,
                    },
                },
            },

            prompts = {
                {
                    role = "user",
                    content = function(context)
                        local behavior = "1. Develop the feature or modify the code as requirements. If code is selected, focus on modifying or completing that specific block. If no code is selected, implement the requested feature by modifying all relevant files in the context.\n" ..
                        "2. If you don't find any useful requirements to implement the code, ask for it\n" ..
                        "3. After implementation, give a detail explanation of what you did.\n"

                        if context.is_visual then
                            local selected_code = utils.wrap_code_with_md(context.code, context.filetype)
                            behavior = behavior .. "4. The selected code of #{buffer} is:\n" .. selected_code .. "\n"
                        else
                            behavior = behavior .. "4. The current file is #{buffer}\n"
                        end

                        behavior = behavior .. "\nUser requirements:\n"
                        return behavior
                    end,
                },
            },
        },
        ["Review code"] = {
            interaction = "chat",
            description = "Review the code with requirements",
            opts = {
                alias = "review_code",
                auto_submit = false,
                modes = { "v", "n", "i" },
                placement = "new",
                ignore_system_prompt = false,
                stop_context_insertion = true,
                is_slash_cmd = true,
            },
            context = {
                {
                    type = "file",
                    path = {
                        utils.AI_ROLES.REVIEWER,
                    },
                },
            },

            prompts = {
                {
                    role = "user",
                    content = function(context)
                        local behavior = "1. If user provides the selected code, just review this part code don't touch others\n" ..
                        "2. If user doesn't provide the selected code, review all the files\n"

                        if context.is_visual then
                            local selected_code = utils.wrap_code_with_md(context.code, context.filetype)
                            behavior = behavior .. "3. The selected code of #{buffer} is:\n" .. selected_code .. "\n"
                        else
                            behavior = behavior .. "3. The current file is #{buffer}\n"
                        end

                        behavior = behavior .. "\nUser requirements:\n"
                        return behavior
                    end,
                },
            },
        },
        ["Brainstorm"] = {
            interaction = "chat",
            description = "Brainstroming how to implement the feature",
            opts = {
                alias = "Brainstorm",
                auto_submit = false,
                modes = { "v", "n" },
                placement = "new",
                ignore_system_prompt = false,
                stop_context_insertion = true,
                is_slash_cmd = true,
            },
            context = {
                {
                    type = "file",
                    path = {
                        utils.AI_ROLES.ARCHITECT,
                        utils.AI_ROLES.BRAINSTORMING,
                    },
                },
            },

            prompts = {
                {
                    role = "user",
                    content = function(context)
                        local behavior = "Follow brainstorming principles to generate plan for:\n"
                        return behavior
                    end,
                },
            },
        },
        ["Fix issue"] = {
            interaction = "chat",
            description = "Analyze and fix the issue",
            opts = {
                alias = "fix_issue",
                auto_submit = false,
                modes = { "v", "n" },
                placement = "new",
                ignore_system_prompt = false,
                stop_context_insertion = true,
                is_slash_cmd = true,
            },
            context = {
                {
                    type = "file",
                    path = {
                        utils.AI_ROLES.ARCHITECT,
                        utils.AI_ROLES.DEVELOPER,
                    },
                },
            },

            prompts = {
                {
                    role = "user",
                    content = function(context)
                        local behavior = "1. Analyze the rootcause with the provided issue and logs.\n" ..
                        "2. If you cannot have enough confidence to find rootcause. Ask me for help to provide the information you need."..
                        "This is important and don't stop until user says he cannot provide anymore, or loops up to 5 asks\n" ..
                        "3. If you don't need other information, find solution how to fix it.\n" ..
                        "4. Finianlly output the result as below:\n" ..
                        "### Analysis\n" ..
                        "[Multiple Analysis results report as Principles describe]\n" ..
                        "### Code change\n" ..
                        "[Code change of the most possilbe solution]\n"..
                        "\nThe issue is:\n"
                        return behavior
                    end,
                },
            },
        },
        ["Analyze issue"] = {
            interaction = "chat",
            description = "Analyze the issue",
            opts = {
                alias = "analyze_issue",
                auto_submit = false,
                modes = { "v", "n" },
                placement = "new",
                ignore_system_prompt = false,
                stop_context_insertion = true,
                is_slash_cmd = true,
            },
            context = {
                {
                    type = "file",
                    path = {
                        utils.AI_ROLES.ANALYZER,
                    },
                },
            },

            prompts = {
                {
                    role = "user",
                    content = function(context)
                        local behavior = "1. Analyze the rootcause with the provided issue and logs.\n" ..
                        "2. If you cannot have enough confidence to find rootcause. Ask me for help to provide the information you need."..
                        "This is important and don't stop until user says he cannot provide anymore, or loops up to 5 asks" ..
                        "3. Finianlly output the result as below:\n" ..
                        "### Analysis\n" ..
                        "[Multiple Analysis results report as Principles describe]\n" ..
                        "4. You can leverage the tools @{read_file}.\n"..
                        "\nThe issue is:\n"
                        return behavior
                    end,
                },
            },
        },
    },
    extensions = {
        spinner = {},
        fs_monitor = {
            enabled = true,
            opts = {
                keymap = "gF", -- Will be changed to `gD` in future releases.
            },
        },
        history = {
            enabled = true,
            opts = {
                -- Keymap to open history from chat buffer (default: gh)
                keymap = "sh",
                -- Keymap to save the current chat manually (when auto_save is disabled)
                save_chat_keymap = "sc",
                -- Save all chats by default (disable to save only manually using 'sc')
                auto_save = true,
                -- Number of days after which chats are automatically deleted (0 to disable)
                expiration_days = 180,
                -- Picker interface (auto resolved to a valid picker)
                picker = "telescope", --- ("telescope", "snacks", "fzf-lua", or "default")
                ---Optional filter function to control which chats are shown when browsing
                chat_filter = nil, -- function(chat_data) return boolean end
                -- Customize picker keymaps (optional)
                picker_keymaps = {
                    rename = { n = "r", i = "<M-r>" },
                    delete = { n = "d", i = "<M-d>" },
                    duplicate = { n = "<C-y>", i = "<C-y>" },
                },
                ---Automatically generate titles for new chats
                auto_generate_title = true,
                title_generation_opts = {
                    ---Adapter for generating titles (defaults to current chat adapter)
                    adapter = nil, -- "copilot"
                    ---Model for generating titles (defaults to current chat model)
                    model = nil, -- "gpt-4o"
                    ---Number of user prompts after which to refresh the title (0 to disable)
                    refresh_every_n_prompts = 0, -- e.g., 3 to refresh after every 3rd user prompt
                    ---Maximum number of times to refresh the title (default: 3)
                    max_refreshes = 3,
                    format_title = function(original_title)
                        -- this can be a custom function that applies some custom
                        -- formatting to the title.
                        return original_title
                    end
                },
                ---On exiting and entering neovim, loads the last chat on opening chat
                continue_last_chat = false,
                ---When chat is cleared with `gx` delete the chat from history
                delete_on_clearing_chat = false,
                ---Directory path to save the chats
                dir_to_save = vim.fn.stdpath("data") .. "/codecompanion-history",
                ---Enable detailed logging for history extension
                enable_logging = false,

                -- Summary system
                summary = {
                    -- Keymap to generate summary for current chat (default: "gcs")
                    create_summary_keymap = "gcs",
                    -- Keymap to browse summaries (default: "gbs")
                    browse_summaries_keymap = "gbs",

                    generation_opts = {
                        adapter = nil, -- defaults to current chat adapter
                        model = nil, -- defaults to current chat model
                        context_size = 90000, -- max tokens that the model supports
                        include_references = true, -- include slash command content
                        include_tool_outputs = true, -- include tool execution results
                        system_prompt = nil, -- custom system prompt (string or function)
                        format_summary = nil, -- custom function to format generated summary e.g to remove <think/> tags from summary
                    },
                },

                -- Memory system (requires VectorCode CLI)
                memory = {
                    -- Automatically index summaries when they are generated
                    auto_create_memories_on_summary_generation = true,
                    -- Path to the VectorCode executable
                    vectorcode_exe = "vectorcode",
                    -- Tool configuration
                    tool_opts = {
                        -- Default number of memories to retrieve
                        default_num = 10
                    },
                    -- Enable notifications for indexing progress
                    notify = true,
                    -- Index all existing memories on startup
                    -- (requires VectorCode 0.6.12+ for efficient incremental indexing)
                    index_on_startup = false,
                },
            }
        }
    }
})

require("fs-monitor").setup({
    monitor = {
        debounce_ms = 300,
        max_file_size = 1024 * 1024 * 2, -- 2MB
        max_prepopulate_files = 2000,
        max_depth = 6,
        max_cache_bytes = 1024 * 1024 * 50, -- 50MB
        ignore_patterns = {},
        respect_gitignore = true,
    },
    diff = {
        -- Window geometry, icons, titles
        -- See lua/fs-monitor/config.lua for all options
    },
})

-- Usage:
-- You can run :checkhealth codecompanion to verify that all requirements are met.
-- How to delete the context? Just delete it in blockquote.
-- Prompt lib: Create a new session and use new system/user prompt.
-- slash_commands: Insert customer prompt in current session/context.
