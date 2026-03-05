-- External functions statement
local utils = require("utils")
local ai_path = utils.ai_path

-- ########################
-- Local function
-- ########################
local function add_context_to_chat(chat, rules)
    -- `rules` is a table of file type
    for _, rule_identifier in ipairs(rules) do
        local rule_data = utils.read_prompt(rule_identifier)
        if not rule_data then
            return vim.notify("Failed to load rule: " .. tostring(rule_identifier), vim.log.levels.ERROR)
        end
        local rule_id = utils.wrap_tag(rule_data.name, "rules")
        chat:add_context({ role = "user", content = rule_data.content }, "file", rule_id)
    end
end

local function insert_code_diff_to_context(callback)
    local items = {
        { label = "Commit (git show)", value = "commit" },
        { label = "Pull Request (gh pr)", value = "pr" },
        { label = "Uncommitted Changes (staged & unstaged)", value = "uncommitted" },
    }

    vim.ui.select(items, {
        prompt = "Select Git Diff Source:",
        format_item = function(item)
            return item.label
        end,
    }, function(choice)
        if not choice then return end

        local results = {}

        -- 辅助函数：读取文件并处理结果，同时提供错误通知
        local function add_file_to_results(filepath, results_table)
            local content = utils.read_file(filepath)
            if content then
                results_table["file:" .. filepath] = content
                return true
            else
                vim.schedule(function()
                    vim.notify(string.format("Failed to read file: %s", filepath), vim.log.levels.WARN)
                end)
                return false
            end
        end

        -- Helper to process files with status
        local function process_files(file_entries, final_callback)
            -- file_entries is a list of { status = "M", path = "file.lua" }
            if #file_entries == 0 then return final_callback() end

            local selected_entries = {}
            -- 使用浅拷贝，因为结构简单
            local remaining_entries = {}
            for _, entry in ipairs(file_entries) do
                table.insert(remaining_entries, { status = entry.status, path = entry.path })
            end

            local function pick_one()
                local file_items = vim.tbl_map(function(e)
                    -- 更灵活的格式化，适应可能超过2字符的状态码
                    return { label = e.status .. " " .. e.path, value = e }
                end, remaining_entries)

                table.insert(file_items, 1, { label = string.format("== DONE (Selected: %d) ==", #selected_entries), value = "done" })
                table.insert(file_items, 2, { label = "== ALL FILES ==", value = "all" })

                vim.ui.select(file_items, {
                    prompt = "Select files to include (one by one):",
                    format_item = function(item) return item.label end
                }, function(file_choice)
                    -- 修复：如果 file_choice 为 nil (按下 <Esc>)，直接返回，不执行 callback
                    if not file_choice then return end

                    if file_choice.value == "done" then
                        for _, e in ipairs(selected_entries) do
                            add_file_to_results(e.path, results)
                        end
                        return final_callback()
                    end

                    if file_choice.value == "all" then
                        for _, e in ipairs(file_entries) do
                            add_file_to_results(e.path, results)
                        end
                        return final_callback()
                    end

                    -- Add to selected
                    table.insert(selected_entries, file_choice.value)
                    -- Remove from remaining
                    for i, e in ipairs(remaining_entries) do
                        if e.path == file_choice.value.path then
                            table.remove(remaining_entries, i)
                            break
                        end
                    end

                    if #remaining_entries == 0 then
                        for _, e in ipairs(selected_entries) do
                            add_file_to_results(e.path, results)
                        end
                        return final_callback()
                    end

                    pick_one()
                end)
            end

            pick_one()
        end

        if choice.value == "commit" then
            vim.ui.input({ prompt = "Enter Commit Hash: " }, function(hash)
                if hash and hash ~= "" then
                    vim.system({ "git", "show", hash }, { text = true }, function(obj)
                        if obj.code == 0 then
                            results.git_diff_ci = obj.stdout
                            -- Get file list with status
                            vim.system({ "git", "show", "--name-status", "--format=", hash }, { text = true }, function(f_obj)
                                local entries = {}
                                if f_obj.code == 0 then
                                    for line in f_obj.stdout:gmatch("[^\r\n]+") do
                                        local status, path = line:match("^(%S+)%s+(.+)$")
                                        if status and path then
                                            table.insert(entries, { status = status, path = path })
                                        end
                                    end
                                end
                                vim.schedule(function()
                                    process_files(entries, function() callback(results) end)
                                end)
                            end)
                        else
                            vim.schedule(function()
                                vim.notify("Failed to get git show for hash: " .. hash, vim.log.levels.ERROR)
                            end)
                        end
                    end)
                end
            end)

        elseif choice.value == "pr" then
            if vim.fn.executable("gh") == 0 then
                vim.notify("GitHub CLI (gh) is not installed or not in PATH.", vim.log.levels.ERROR)
                return
            end
            vim.ui.input({ prompt = "Enter PR ID: " }, function(pr_id)
                if pr_id and pr_id ~= "" then
                    vim.system({ "gh", "pr", "view", pr_id, "--json", "body,commits,title,files" }, { text = true }, function(info_obj)
                        if info_obj.code ~= 0 then
                            return vim.schedule(function()
                                vim.notify("Failed to get PR info for ID: " .. pr_id, vim.log.levels.ERROR)
                            end)
                        end

                        vim.system({ "gh", "pr", "diff", pr_id }, { text = true }, function(diff_obj)
                            if diff_obj.code == 0 then
                                results.git_diff_pr = string.format("PR Info:\n%s\n\nPR Diff:\n%s", info_obj.stdout, diff_obj.stdout)
                                local ok, info = pcall(vim.json.decode, info_obj.stdout)
                                local entries = {}
                                if ok and info.files then
                                    local status_map = { MODIFIED = "M", ADDED = "A", DELETED = "D", RENAMED = "R" }
                                    for _, f in ipairs(info.files) do
                                        table.insert(entries, { status = status_map[f.status] or f.status:sub(1, 1), path = f.path })
                                    end
                                end
                                vim.schedule(function()
                                    process_files(entries, function() callback(results) end)
                                end)
                            else
                                vim.schedule(function()
                                    vim.notify("Failed to get PR diff for ID: " .. pr_id, vim.log.levels.ERROR)
                                end)
                            end
                        end)
                    end)
                end
            end)

        elseif choice.value == "uncommitted" then
            vim.system({ "git", "diff", "--cached" }, { text = true }, function(staged_obj)
                if staged_obj.code ~= 0 then
                    return vim.schedule(function() vim.notify("Git diff staged failed", vim.log.levels.ERROR) end)
                end
                vim.system({ "git", "diff" }, { text = true }, function(unstaged_obj)
                    if unstaged_obj.code ~= 0 then
                        return vim.schedule(function() vim.notify("Git diff failed", vim.log.levels.ERROR) end)
                    end
                    if staged_obj.stdout ~= "" then results.git_diff_staged = staged_obj.stdout end
                    if unstaged_obj.stdout ~= "" then results.git_diff_unstaged = unstaged_obj.stdout end

                    -- Get file list with status
                    vim.system({ "git", "diff", "--name-status" }, { text = true }, function(u_f_obj)
                        vim.system({ "git", "diff", "--cached", "--name-status" }, { text = true }, function(s_f_obj)
                            local entries_map = {}
                            local function parse_output(stdout)
                                for line in stdout:gmatch("[^\r\n]+") do
                                    local status, path = line:match("^(%S+)%s+(.+)$")
                                    if status and path then
                                        entries_map[path] = status
                                    end
                                end
                            end
                            if u_f_obj.code == 0 then parse_output(u_f_obj.stdout) end
                            if s_f_obj.code == 0 then parse_output(s_f_obj.stdout) end

                            local entries = {}
                            for path, status in pairs(entries_map) do
                                table.insert(entries, { status = status, path = path })
                            end
                            table.sort(entries, function(a, b) return a.path < b.path end)

                            vim.schedule(function()
                                if next(results) then
                                    process_files(entries, function() callback(results) end)
                                else
                                    vim.notify("No changes detected", vim.log.levels.INFO)
                                end
                            end)
                        end)
                    end)
                end)
            end)
        end
    end)
end

local function change_adapter_to_gemini_lite(chat)
    local adapter = {name = "gemini", model = "gemini-2.5-flash"}
    chat:change_adapter(adapter)
    vim.notify("Model updated to: " .. adapter.model, vim.log.levels.INFO, { title = "CodeCompanion" })
end


local function handle_cc_setting(opts)
    local config = require("codecompanion.config")
    if not config then
        return vim.notify("CodeCompanion config not found", vim.log.levels.ERROR)
    end

    local args = opts.fargs
    local key = args[1]
    local val = args[2]

    -- 获取当前默认的聊天适配器名称
    local adapter_name = config.interactions.chat.adapter.name
    local adapter_config = config.adapters.http[adapter_name]

    if not adapter_config then
        return vim.notify("Adapter config for " .. adapter_name .. " not found", vim.log.levels.ERROR)
    end

    -- 关键修复：处理函数类型的适配器配置
    local config_table
    if type(adapter_config) == "function" then
        -- 执行工厂函数获取实际配置表
        config_table = adapter_config()
    else
        -- 已经是表，直接使用
        config_table = adapter_config
    end

    if key == "temperature" then
        local num = tonumber(val)
        if num then
            config_table.schema.temperature.default = num
            vim.notify(string.format("CC: %s temperature set to %.1f", adapter_name, num), vim.log.levels.INFO)
        else
            vim.notify("Invalid temperature value", vim.log.levels.ERROR)
        end
    elseif key == "thinking" then
        if vim.tbl_contains({ "low", "medium", "high" }, val) then
            config_table.schema.reasoning_effort.default = val
            vim.notify(string.format("CC: %s reasoning_effort set to %s", adapter_name, val), vim.log.levels.INFO)
        else
            vim.notify("Invalid thinking level: use low, medium, or high", vim.log.levels.ERROR)
        end
    end

    -- 更新配置（如果是函数类型，需要用新表替换原函数）
    if type(adapter_config) == "function" then
        config.adapters.http[adapter_name] = config_table
    end
end


-- ########################
-- NVIM command
-- ########################
vim.api.nvim_create_user_command("Ccsetting", handle_cc_setting, {
    nargs = "+",
    desc = "Dynamically configure CodeCompanion settings",
    complete = function(ArgLead, CmdLine, CursorPos)
        local args = vim.split(CmdLine, "%s+")
        -- 过滤掉空字符串（由于末尾空格导致）
        args = vim.tbl_filter(function(s) return s ~= "" end, args)

        -- 如果正在输入第一个参数 (key)
        if #args == 1 or (#args == 2 and CmdLine:sub(-1) ~= " ") then
            return vim.tbl_filter(function(item)
                return item:find(ArgLead)
            end, { "temperature", "thinking" })
        end

        -- 如果正在输入第二个参数 (value)
        if #args == 2 or (#args == 3 and CmdLine:sub(-1) ~= " ") then
            local key = args[2]
            if key == "thinking" then
                return vim.tbl_filter(function(item)
                    return item:find(ArgLead)
                end, { "low", "medium", "high" })
            elseif key == "temperature" then
                return { "0.1", "0.5", "0.9" }
            end
        end
    end,
})

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
                            default = "low",
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
                ["git_message"] = {
                    description = "Generate the commit message for the change",
                    callback = function(chat)
                        local staged = utils.run_cmd("git diff --cached")
                        local unstaged = utils.run_cmd("git diff")

                        if (staged == "" or staged == nil) and (unstaged == "" or unstaged == nil) then
                            return vim.notify("No git changes detected", vim.log.levels.INFO, { title = "CodeCompanion" })
                        end

                        if staged ~= "" then
                            chat:add_context({ role = "user", content = staged }, "git", "staged_diff")
                        end
                        if unstaged ~= "" then
                            chat:add_context({ role = "user", content = unstaged }, "git", "unstaged_diff")
                        end

                        chat:toggle_system_prompt()
                        chat:add_buf_message({
                            role = "user",
                            content = "I've provided the git changes in the attachment."..
                                "Generate a concise and clear git commit message for these changes using the Conventional Commits format." ..
                                "Message is 20 ~ 150 words and should be English."..
                                "Just provide the text message with format ```text```, no need explanation."..
                                "Commit Type could be one of `feat`, `fix`, `refactor`, `docs`, `test`."..
                                "The message should be limited to 90 characters one line."..
                                "If there're multiple changes, use number to list most 5 important items."
                        })
                        change_adapter_to_gemini_lite(chat)
                    end,
                },
                ["git_diff"] = {
                    description = "Insert git diff into context",
                    callback = function(chat)
                        insert_code_diff_to_context(function(diffs)
                            for key, content in pairs(diffs) do
                                chat:add_context({
                                    role = "user",
                                    content = content,
                                }, "git_diff", key)
                            end
                        end)
                    end,
                },
                ["apply"] = {
                    description = "Apply the code change to current buffer",
                    callback = function(chat)
                        change_adapter_to_gemini_lite(chat)
                        chat:add_buf_message({
                            role = "user",
                            content = "Use @{insert_edit_into_file} to apply the change.\n"..
                                "And tell me if done or not."
                        })
                    end,
                },
            },
            editor_context = {
                ["buffer"] = {
                    opts = {
                        -- Always sync the buffer by sharing its "diff"
                        -- Or choose "all" to share the entire buffer
                        default_params = "all",
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
                    modes = { n = { "<CR>" }, i = "<C-d>" },
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
            }

        },
        inline = {
            adapter = {
                name = "gemini",
                model = "gemini-2.5-flash",
            },
        },
        cmd = {
            adapter = {
                name = "gemini",
                model = "gemini-2.5-flash-lite",
            },
        },
        background = {
            adapter = {
                name = "gemini",
                model = "gemini-2.5-flash-lite",
            },
        },
        shared = {
            keymaps = {
                always_accept = {
                    callback = "keymaps.always_accept",
                    modes = { n = "g1" },
                },
                accept_change = {
                    callback = "keymaps.accept_change",
                    modes = { n = "g2" },
                },
                reject_change = {
                    callback = "keymaps.reject_change",
                    modes = { n = "g3" },
                },
                next_hunk = {
                    callback = "keymaps.next_hunk",
                    modes = { n = "}" },
                },
                previous_hunk = {
                    callback = "keymaps.previous_hunk",
                    modes = { n = "{" },
                },
            },
        },
    },
    display = {
        action_palette = {
            opts = {
                show_preset_prompts = false
            }
        },
        chat = {
            window = {
                buflisted = false, -- List the chat buffer in the buffer list?
                sticky = false, -- Chat buffer remains open when switching tabs

                layout = "vertical", -- float|vertical|horizontal|buffer
                full_height = true, -- for vertical layout
                position = nil, -- left|right|top|bottom (nil will default depending on vim.opt.splitright|vim.opt.splitbelow)

                width = 0.6,
                height = 0.8,
                border = "rounded",
                relative = "editor",
            },
            intro_message = "Welcome to CodeCompanion ✨! Press ? for options | ⌨️ <C-d> Submit)",
            separator = "─", -- 消息之间的分隔符
            show_header_separator = true, -- 是否显示标题分隔符
            show_settings = false, -- 是否在顶部显示模型参数设置
            start_in_insert_mode = false, -- 打开时是否直接进入插入模式
            fold_reasoning = true, -- Fold the reasoning content in the chat buffer?
            show_reasoning = true, -- Show reasoning content in the chat buffer?
            token_count = function(tokens, adapter)
                local metadata = _G.codecompanion_chat_metadata[vim.api.nvim_get_current_buf()]

                local info = {
                    -- string.format("󰚩 %s", adapter.schema.model.default),
                    string.format("🪙 %s", tokens),
                }

                if metadata and metadata.cycles then
                    table.insert(info, string.format("🔄 %s", metadata.cycles))
                end

                --[[
                   [ if metadata and metadata.context_items and metadata.context_items > 0 then
                   [     table.insert(info, string.format("📂 %s", metadata.context_items))
                   [ end
                   ]]

                if metadata and metadata.tools and metadata.tools > 0 then
                    table.insert(info, string.format("🛠️ %s", metadata.tools))
                end

                return " (" .. table.concat(info, " · ")
            end,
        },
        diff = {
            enabled = true,
            word_highlights = {
                additions = true,
                deletions = true,
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
        role_develop = {
            description = "A professional developer",
            files = {
                utils.AI_ROLES.DEVELOPER,
            },
        },
    },

    prompt_library = {
        -- Use `:CodeCompanionActions refresh` to apply the new added prompt
        -- ------------ --
        -- Minor workflow
        ["New chat"] = {
            interaction = "chat",
            description = "Launch a new chat session",
            opts = {
                alias = "new_chat",
                auto_submit = false,
                modes = { "v", "n" },
                placement = "new",
                ignore_system_prompt = false,
                stop_context_insertion = true,
                is_slash_cmd = true,
            },
            prompts = {
                {
                    role = "user",
                    content = function(context)
                        local behavior = ""

                        if context.is_visual then
                            local selected_code = utils.wrap_code_with_md(context.code, context.filetype)
                            behavior = behavior .. "The selected code of #{buffer} is:\n" .. selected_code .. "\n"
                        else
                            behavior = behavior .. "The current file is #{buffer}.\n"
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
                        "```\n### What's it?\n" ..
                        "[Provide a detail description/explaination of 'What is it? What is it used for?]\n" ..
                        "### Example\n" ..
                        "[Use an example to illustrate the workflow of it or how to use it.]\n" ..
                        "### Important components\n" ..
                        "[What's the important components? How to use them?]\n" ..
                        "[List important data structures and functions and comment for what they used for.]\n" ..
                        "### Why design that?\n" ..
                        "[benefits, trade-offs, pros and cons, ...]\n" ..
                        "### Intergration\n" ..
                        "[How does it work with other modules?]\n```\n" ..
                        "2. Use the selected code as the target. If no selected code, user should provide one. If user doesn't provide target, ask for it.\n"

                        if context.is_visual then
                            local selected_code = utils.wrap_code_with_md(context.code, context.filetype)
                            behavior = behavior .. "3. The selected code of #{buffer} is:\n" .. selected_code .. "\n"
                        else
                            behavior = behavior .. "\nThe target/question is:"
                        end

                        return behavior
                    end,
                },
            },
        },
        -- ------------ --
        -- Development
        --
        ["Design plan"] = {
            interaction = "chat",
            description = "Generate a design plan based on requirements",
            opts = {
                alias = "design",
                auto_submit = false,
                modes = { "v", "n" },
                placement = "new",
                ignore_system_prompt = false,
                stop_context_insertion = true,
                is_slash_cmd = true,
            },
            --[[
               [ tools = {
               [     "run_command",
               [     "insert_edit_into_file",
               [ },
               ]]
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
                        local behavior = "Tools: @{run_cmd}, @{insert_edit_into_file}\n"..
                        "Follow brainstorming principles to generate design for user requirements:\n"

                        if context.is_visual then
                            local selected_code = utils.wrap_code_with_md(context.code, context.filetype)
                            behavior = behavior .. "\nSelected code in #{buffer}:\n" .. selected_code .. "\n"
                        end

                        return behavior
                    end,
                },
            },
        },
        ["Develop code"] = {
            interaction = "chat",
            description = "Based on `Analysis report` or `Review report` or `Design plan` or `User requirements` to Implement the code",
            opts = {
                alias = "develop",
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
                        local behavior = "You're a Senior Principal Engineer to implement the code.\n" ..
                        "1. Implement code based on `Analysis report` or `Review report` or `Design plan` or `User requirements`. If you don't find any one, ask for what to implement.\n" ..
                        "2. If code is selected, just focus on modifying or completing that specific block. If no code is selected, implement the requested feature by modifying all relevant files in the context.\n" ..
                        "3. Give a detail explanation of what you do before apply the change.\n"

                        if context.is_visual then
                            local selected_code = utils.wrap_code_with_md(context.code, context.filetype)
                            behavior = behavior .. "\nSelected code in #{buffer}:\n" .. selected_code .. "\n"
                        end

                        behavior = behavior .. "\nUser requirements:\n"
                        return behavior
                    end,
                },
            },
        },
        ["Analyze issue"] = {
            interaction = "chat",
            description = "Based on the `Failing test log` or `Issue description` to generate the Analyze report",
            opts = {
                alias = "analyze",
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
                        local behavior = "1. Analyze the rootcause with the `Failing test log` or `Issue description`.\n" ..
                        "2. If you cannot have enough confidence to find rootcause. Ask me for help to provide the information you need. This is important and don't stop until user says he cannot provide anymore, or loops up to 5 asks.\n" ..
                        "3. Finally output the result as below:\n" ..
                        "```\n### Analysis\n[Analysis report as Principles describe]\n```\n"..
                        "4. Tools: @{read_file}\n"

                        if context.is_visual then
                            local selected_code = utils.wrap_code_with_md(context.code, context.filetype)
                            behavior = behavior .. "\nContext information from #{buffer}:\n" .. selected_code .. "\n"
                        end

                        behavior = behavior .. "\nThe issue is:\n"
                        return behavior
                    end,
                },
            },
        },
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
                        "```\n### Summary\n" ..
                        "[Provide a detail description/explaination of 'What is it? What is it used for?]\n" ..
                        "### Code explain\n" ..
                        "[Provide detailed, code-level explaination, similar to in-line code comments for the selected code]\n" ..
                        "### Example\n" ..
                        "[Use an example to illustrate the workflow of it or how to use it]\n```\n" ..
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
        ["Review code"] = {
            interaction = "chat",
            description = "Do the code review for PR/CI/Staged/Selected code",
            opts = {
                alias = "review_code",
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
                        utils.AI_ROLES.REVIEWER,
                    },
                },
            },
            prompts = {
                {
                    role = "user",
                    content = function(context)
                        local behavior = "You're a Senior Principal Engineer to do the comprehensively code review with attached principles.\n"..
                        "1. If user provides the selected code, just review this part code don't touch others.\n" ..
                        "2. If user doesn't provide the selected code, do  review for the attached diff change.\n"

                        if context.is_visual then
                            local selected_code = utils.wrap_code_with_md(context.code, context.filetype)
                            behavior = behavior .. "The selected code of #{buffer} is:\n" .. selected_code .. "\n"
                        else
                            behavior = behavior .. "/git"
                        end

                        return behavior
                    end,
                },
            },
        },
        ["Modify code"] = {
            interaction = "inline",
            description = "Modify or complete code",
            opts = {
                alias = "modify_code",
                auto_submit = false,
                modes = { "v", "n" },
                placement = "replace",
                ignore_system_prompt = true,
                stop_context_insertion = true,
                is_slash_cmd = false,
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
                        local behavior = "You're a Principal Engineer to modify or complete the code."..
                        "No explaination just provide the code"
                        if context.is_visual then
                            local selected_code = utils.wrap_code_with_md(context.code, context.filetype)
                            behavior = behavior .. "The selected code of #{buffer} is:\n" .. selected_code .. "\n"
                        end

                        local user_requirements = vim.fn.input("Input your requirements (<Enter> to Submit): ")
                        if user_requirements and user_requirements ~= "" then
                            behavior = behavior .. "\nUser requirements: " .. user_requirements .. "\n"
                        end

                        return behavior
                    end,
                },
            },
        },
    },
    extensions = {
        spinner = {},
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

-- Usage:
-- You can run :checkhealth codecompanion to verify that all requirements are met.
-- How to delete the context? Just delete it in blockquote.
-- Prompt lib: Create a new session and use new system/user prompt.
-- slash_commands: Insert customer prompt in current session/context.
--
-- Develop Workflow:
--
-- # Feature development:
-- /design:  Based on user requirements to genrate the design plan
-- /develop: Based on desing plan to Implement the code
-- /review:  Based on the code diff to generate the review report
-- /develop: Based on review report to Implement the code
--
-- # Minor feature development:
-- /develop: Based on user requirment to Implement the code
-- /review:  Based on the code diff to generate the review report
-- /develop: Based on review report to Implement the code
--
-- # Debug:
-- /analyze: Based on the `Failing test log` or `Issue description` to generate the Analyze report
-- /develop: Based on Analyze report to Implement the code
-- /review:  Based on the code diff to generate the review report
-- /develop: Based on review report to Implement the code
