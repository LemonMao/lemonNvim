local utils = require("utils")
local ai_path = utils.ai_path
local read_file = utils.read_file
local AI_prompt = utils.AI_prompt
local cmp = require("cmp")
local minuet_action = require("minuet.virtualtext").action

-- ## ------------------------------ ##
-- ## Configuration & State
-- ## ------------------------------ ##

local ai_state = {
    range = nil,
}

local config = {
    models = {
        ["gemini-2.5-flash-lite"] = {
            provider = "gemini",
            endpoint = "https://generativelanguage.googleapis.com/v1beta/models",
            model = "gemini-2.5-flash-lite",
            api_key = os.getenv("GEMINI_API_KEY") or "",
        },
        ["gemini-2.5-flash"] = {
            provider = "gemini",
            endpoint = "https://generativelanguage.googleapis.com/v1beta/models",
            model = "gemini-2.5-flash",
            api_key = os.getenv("GEMINI_API_KEY") or "",
        },
        ["deepseek-chat"] = {
            provider = "openai",
            endpoint = "https://api.deepseek.com",
            model = "deepseek-chat",
            api_key = os.getenv("DEEPSEEK_API_KEY") or "",
        },
        ["deepseek-reasoner"] = {
            provider = "openai",
            endpoint = "https://api.deepseek.com",
            model = "deepseek-reasoner",
            api_key = os.getenv("DEEPSEEK_API_KEY") or "",
        },
    },
    defaults = {
        translation = "gemini-2.5-flash-lite",
        explanation = "gemini-2.5-flash",
        bashcommand = "gemini-2.5-flash",
    },
    model_groups = {
        deepseek = {
            translation = "deepseek-chat",
            explanation = "deepseek-chat",
            bashcommand = "deepseek-chat",
            completion  = "openai_fim_compatible:deepseek-chat",
        },
        gemini = {
            translation = "gemini-2.5-flash-lite",
            explanation = "gemini-2.5-flash",
            bashcommand = "gemini-2.5-flash",
            completion  = "gemini:gemini-2.5-flash",
        },
    },
    bash_history_size = 10,
    prompts = {
        translate = read_file(ai_path .. "/translation.prt"),
        explain = AI_prompt("A professional software engineer.",
            "1. Explain the target/question as following output:\n" ..
            "## What's it?\n" ..
            "[Provide a detail description/explanation of 'What is it? What is it used for?]\n" ..
            "## Example\n" ..
            "[Use an example to illustrate the workflow of it or how to use it.]\n" ..
            "## Important components\n" ..
            "[List important data structures and functions and comment for what they used for.]\n" ..
            "2. Use the selected code as the target. If no selected code, user should provide one. If user doesn't provide target, ask for it."),
        bash = "You are a professional Linux system administrator. " ..
            "Your task is to provide the exact BASH command for the user's request. " ..
            "Rules:\n1. ONLY output the command itself.\n2. DO NOT include explanations or markdown blocks.\n" ..
            "3. Join multiple commands with ' && '.\n4. Ensure safety."
    }
}

-- ## ------------------------------ ##
-- ## Core API
-- ## ------------------------------ ##

local function get_model_config(type)
    local name = config.defaults[type]
    return config.models[name]
end

-- Initialize global state for status line
vim.g.ai_current_model_group = "gemini"

local function change_model_group(group_name)
    local group = config.model_groups[group_name]
    if not group then
        local available = table.concat(vim.tbl_keys(config.model_groups), ", ")
        vim.notify("Unknown model group: " .. group_name .. ". Available: " .. available, vim.log.levels.ERROR)
        return
    end

    -- Update internal defaults
    config.defaults.translation = group.translation
    config.defaults.explanation = group.explanation
    config.defaults.bashcommand = group.bashcommand

    -- Update global state for UI
    vim.g.ai_current_model_group = group_name

    -- Update Minuet plugin model
    local minuet_cmd = string.format("Minuet change_model %s", group.completion)
    local ok, err = pcall(vim.cmd, minuet_cmd)
    if not ok then
        vim.notify("Minuet update failed: " .. tostring(err), vim.log.levels.WARN)
    end

    vim.notify("AI Model group changed to: " .. group_name, vim.log.levels.INFO)
end

-- Register Ex command
vim.api.nvim_create_user_command("LLMModelChange", function(opts)
    change_model_group(opts.args)
end, {
    nargs = 1,
    complete = function()
        return vim.tbl_keys(config.model_groups)
    end,
    desc = "Change AI model group (e.g., deepseek, gemini)"
})

local function call_llm_api(text, prompt, model_config, callback)
    if not model_config or model_config.api_key == "" then
        vim.notify("Invalid model config or missing API key", vim.log.levels.ERROR)
        return
    end

    local url, json_body, auth_header
    if model_config.provider == "gemini" then
        url = string.format("%s/%s:generateContent?key=%s", model_config.endpoint, model_config.model, model_config.api_key)
        json_body = vim.fn.json_encode({
            contents = { { role = "user", parts = { { text = text } } } },
            systemInstruction = { parts = { { text = prompt } } },
        })
    elseif model_config.provider == "openai" then
        url = model_config.endpoint
        json_body = vim.fn.json_encode({
            model = model_config.model,
            messages = {
                { role = "system", content = prompt },
                { role = "user", content = text },
            },
        })
        auth_header = string.format(' -H "Authorization: Bearer %s"', model_config.api_key)
    else
        vim.notify("Unsupported provider: " .. (model_config.provider or "nil"), vim.log.levels.ERROR)
        return
    end

    local cmd = string.format('curl -s -X POST -H "Content-Type: application/json"%s --data @- "%s" <<< %s',
        auth_header or "", url, vim.fn.shellescape(json_body))

    local chunks = {}
    vim.fn.jobstart(cmd, {
        on_stdout = function(_, data) for _, v in ipairs(data) do table.insert(chunks, v) end end,
        on_stderr = function(_, data)
            local err = table.concat(data, "")
            if err ~= "" then vim.notify("API Error: " .. err, vim.log.levels.ERROR) end
        end,
        on_exit = function()
            local resp = table.concat(chunks, "")
            local ok, parsed = pcall(vim.fn.json_decode, resp)
            if ok and parsed then
                if parsed.error then
                    vim.notify("API Error: " .. (parsed.error.message or "Unknown"), vim.log.levels.ERROR)
                elseif model_config.provider == "gemini" and parsed.candidates and parsed.candidates[1] then
                    callback(parsed.candidates[1].content.parts[1].text)
                elseif model_config.provider == "openai" and parsed.choices and parsed.choices[1] then
                    callback(parsed.choices[1].message.content)
                else
                    vim.notify("Failed to parse API response", vim.log.levels.ERROR)
                end
            else
                vim.notify("Failed to parse API response", vim.log.levels.ERROR)
            end
        end,
    })
end

-- ## ------------------------------ ##
-- ## UI Helpers
-- ## ------------------------------ ##

local function show_floating_result(result)
    local buf = vim.api.nvim_create_buf(false, true)
    local width, height = math.floor(vim.o.columns * 0.8), math.floor(vim.o.lines * 0.8)
    local win = vim.api.nvim_open_win(buf, true, {
        relative = "editor", width = width, height = height,
        col = (vim.o.columns - width) / 2, row = (vim.o.lines - height) / 2,
        style = "minimal", border = "rounded",
    })

    local help_text = { "", "--------  Hot Keys --------", "Close: q/Esc", "Save: <A-q>", "Replace: <A-r>" }
    local lines = vim.split(result, "\n")
    local content_end = #lines
    for _, v in ipairs(help_text) do table.insert(lines, v) end

    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_buf_set_option(buf, "modifiable", false)
    vim.api.nvim_buf_set_option(buf, "filetype", "markdown")

    -- Mappings
    local opts = { buffer = buf, noremap = true, silent = true }
    vim.keymap.set("n", "q", "<cmd>q<CR>", opts)
    vim.keymap.set("n", "<Esc>", "<cmd>q<CR>", opts)
    vim.keymap.set("n", "<A-q>", function()
        local content = vim.api.nvim_buf_get_lines(buf, 0, content_end, false)
        local path = "/tmp/AI_" .. os.date("%Y%m%d_%H%M%S") .. ".md"
        vim.fn.writefile(content, path)
        vim.api.nvim_win_close(win, true)
        vim.cmd("edit " .. path)
    end, opts)
    vim.keymap.set("n", "<A-r>", function()
        local content = vim.api.nvim_buf_get_lines(buf, 0, content_end, false)
        vim.api.nvim_win_close(win, true)
        if ai_state.range then
            local r = ai_state.range
            if vim.api.nvim_win_is_valid(r.winid) then
                vim.api.nvim_set_current_win(r.winid)
                vim.api.nvim_buf_set_text(r.bufnr, r.start_row, r.start_col, r.end_row, r.end_col, content)
            else
                vim.notify("Target window no longer valid", vim.log.levels.WARN)
            end
            ai_state.range = nil
        end
    end, opts)
end

-- ## ------------------------------ ##
-- ## Context Management
-- ## ------------------------------ ##

local function get_text_and_range()
    local mode = vim.fn.mode()
    local text, range = "", nil
    local bufnr, winid = vim.api.nvim_get_current_buf(), vim.api.nvim_get_current_win()

    if mode == "n" then
        text = vim.fn.expand("<cword>")
        local cursor = vim.api.nvim_win_get_cursor(0)
        vim.cmd('normal! viw\27')
        local s, e = vim.fn.getpos("'<"), vim.fn.getpos("'>")
        vim.api.nvim_win_set_cursor(0, cursor)
        range = { bufnr = bufnr, winid = winid, start_row = s[2]-1, start_col = s[3]-1, end_row = e[2]-1, end_col = e[3] }
    elseif mode:match("[vV]") then
        vim.cmd('normal! \27')
        local s, e = vim.fn.getpos("'<"), vim.fn.getpos("'>")
        local line = vim.api.nvim_buf_get_lines(bufnr, e[2]-1, e[2], false)[1]
        local ecol = (vim.fn.visualmode() == "V") and #line or math.min(e[3], #line)

        if vim.fn.visualmode() == "V" then
            text = table.concat(vim.api.nvim_buf_get_lines(bufnr, s[2]-1, e[2], false), "\n")
        else
            text = table.concat(vim.api.nvim_buf_get_text(bufnr, s[2]-1, s[3]-1, e[2]-1, ecol, {}), "\n")
        end

        range = { bufnr = bufnr, winid = winid, start_row = s[2]-1, start_col = s[3]-1, end_row = e[2]-1, end_col = ecol }
    end

    if text ~= "" then
        -- Remove trailing whitespace from selected text
        text = text:gsub("%s*$", "")
        ai_state.range = range
    end
    return text ~= "" and text or nil
end

-- ## ------------------------------ ##
-- ## Actions
-- ## ------------------------------ ##

local function ai_translate()
    local text = get_text_and_range()
    if text then
        vim.notify("Translating...", vim.log.levels.INFO)
        call_gemini_api(text, config.prompts.translate, get_model_config("translation"), show_floating_result)
    end
end

local function ai_explain()
    local text = get_text_and_range()
    if text then
        vim.notify("Explaining...", vim.log.levels.INFO)
        call_gemini_api(text, config.prompts.explain, get_model_config("explanation"), show_floating_result)
    end
end

local function ai_avante_explain()
    local text = get_text_and_range()
    if not text then return end
    -- Wrap the selected code with specific markers and include the explain command
    local wrapped = string.format("#explain_code\n--selected code start---\n%s\n--selected code end---", text)
    local ok, avante = pcall(require, "avante.api")
    if ok then
        avante.ask({ new_chat=true, question = wrapped })
    else
        vim.notify("Avante API not found", vim.log.levels.ERROR)
    end
end

local function ai_explain_function()
    -- Check if current file type is C/C++
    local filetype = vim.bo.filetype
    local c_filetypes = { "c", "cpp", "cxx", "cc", "h", "hpp" }
    local is_c_file = false

    for _, ft in ipairs(c_filetypes) do
        if filetype == ft then
            is_c_file = true
            break
        end
    end

    if not is_c_file then
        vim.notify("AI explain function only works for C/C++ files (current: " .. filetype .. ")", vim.log.levels.WARN)
        return
    end

    local symbol = vim.fn.expand("<cword>")
    if symbol == "" then
        vim.notify("No symbol under cursor", vim.log.levels.WARN)
        return
    end

    local path = "/tmp/AI_Func_" .. os.date("%Y%m%d_%H%M%S") .. ".md"
    local cmd = string.format("callGraph.py --codebase %s --depth 2 --start %s --explain_to %s",
        vim.fn.shellescape(vim.fn.getcwd()), vim.fn.shellescape(symbol), vim.fn.shellescape(path))
    vim.notify("Analyzing CallGraph...", vim.log.levels.INFO)
    vim.fn.jobstart(cmd, { on_exit = function(_, code)
        if code == 0 then vim.cmd("edit " .. path) else vim.notify("Failed", vim.log.levels.ERROR) end
    end })
end

local function ai_bash()
    local chan = vim.bo.channel
    if chan == 0 then return end
    -- Get terminal context and trim trailing blank lines
    local terminal_ctx = table.concat(vim.api.nvim_buf_get_lines(0, -50, -1, false), "\n"):gsub("%s*$", "")

    -- Initialize history
    if not ai_state.history then ai_state.history = {} end
    ai_state.history_index = #ai_state.history + 1

    local buf = vim.api.nvim_create_buf(false, true)
    local win = vim.api.nvim_open_win(buf, true, {
        relative = "editor", width = 80, height = 2,
        col = (vim.o.columns - 80) / 2, row = (vim.o.lines - 4) / 2,
        style = "minimal", border = "rounded",
        title = " AI Bash Command ",
        title_pos = "center",
        footer = {
            { " ", "FloatFooter" },
            { "[Enter]", "DiagnosticError" },
            { " Submit | ", "FloatFooter" },
            { "[Ctrl+Enter]", "DiagnosticError" },
            { " New Line | ", "FloatFooter" },
            { "[Ctrl+p]", "DiagnosticError" },
            { "/", "FloatFooter" },
            { "[Ctrl+n]", "DiagnosticError" },
            { " History | ", "FloatFooter" },
            { "[Esc]", "DiagnosticError" },
            { " Quit ", "FloatFooter" },
        },
        footer_pos = "center",
    })

    -- Disable cmp for this buffer to avoid keymap conflicts
    pcall(function() cmp.setup.buffer { enabled = false } end)

    -- Navigation functions
    local function previous_prompt()
        if not ai_state.history or #ai_state.history == 0 then
            vim.notify("No history", vim.log.levels.INFO)
            return
        end
        if ai_state.history_index > 1 then
            ai_state.history_index = ai_state.history_index - 1
            local lines = vim.split(ai_state.history[ai_state.history_index], "\n")
            vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
            -- Move cursor to end of last line
            vim.api.nvim_win_set_cursor(win, { #lines, #lines[#lines] })
        else
            vim.notify("Beginning of history", vim.log.levels.INFO)
        end
    end

    local function next_prompt()
        if not ai_state.history or #ai_state.history == 0 then
            vim.notify("No history", vim.log.levels.INFO)
            return
        end
        if ai_state.history_index < #ai_state.history then
            ai_state.history_index = ai_state.history_index + 1
            local lines = vim.split(ai_state.history[ai_state.history_index], "\n")
            vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
            vim.api.nvim_win_set_cursor(win, { #lines, #lines[#lines] })
        elseif ai_state.history_index == #ai_state.history then
            ai_state.history_index = ai_state.history_index + 1
            vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "" })
            vim.api.nvim_win_set_cursor(win, { 1, 0 })
        else
            vim.notify("Already at newest", vim.log.levels.INFO)
        end
    end

    -- Enter to submit
    vim.keymap.set("i", "<CR>", function()
        local req = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")
        vim.api.nvim_win_close(win, true)
        vim.cmd("stopinsert")
        if not req:match("%S") then return end

        -- Add to history
        table.insert(ai_state.history, req)
        ai_state.history_index = #ai_state.history + 1

        -- Trim history if exceeds configured size
        while #ai_state.history > config.bash_history_size do
            table.remove(ai_state.history, 1)
        end

        local prompt = config.prompts.bash .. "\nContext:\n" .. terminal_ctx
        call_gemini_api(req, prompt, get_model_config("bashcommand"), function(res)
            local cmd = res:gsub("```%w*", ""):gsub("```", ""):gsub("^%s*", ""):gsub("%s*$", "")
            vim.api.nvim_chan_send(chan, cmd)
        end)
    end, { buffer = buf })

    -- Ctrl+Enter to break new line
    vim.keymap.set("i", "<C-CR>", function()
        vim.api.nvim_put({ "" }, "c", false, true)
    end, { buffer = buf })

    -- History navigation
    local map_opts = { buffer = buf, nowait = true, silent = true }
    vim.keymap.set({ "i", "n" }, "<C-p>", previous_prompt, map_opts)
    vim.keymap.set({ "i", "n" }, "<C-n>", next_prompt, map_opts)

    -- Esc to quit
    vim.keymap.set({ "i", "n" }, "<Esc>", function()
        vim.api.nvim_win_close(win, true)
        vim.cmd("stopinsert")
    end, { buffer = buf })

    vim.cmd("startinsert")
end

local function ai_completion()
    if cmp.visible() then
        cmp.abort()
        minuet_action.next()
    else
        minuet_action.next()
    end
end

local function ai_dismiss()
    cmp.abort()
    minuet_action.dismiss()
end

-- ## ------------------------------ ##
-- ## LLM Context Generation
-- ## ------------------------------ ##

local function get_ctx_file() return "/tmp/llm_ctx_" .. vim.fn.getpid() .. ".md" end

local function ai_add_context()
    local text = get_text_and_range()
    if text then
        local file = get_ctx_file()
        local fd = io.open(file, "a")
        if fd then
            fd:write("----------------------------------------------------\n" .. text .. "\n")
            fd:close()
        end
    end
end

local function ai_clean_context()
    vim.fn.writefile({}, get_ctx_file())
    vim.cmd("edit " .. get_ctx_file())
end

-- ## ------------------------------ ##
-- ## Keymaps
-- ## ------------------------------ ##

vim.keymap.set({ "n", "v" }, "<leader>at", ai_translate, { desc = "AI: Translate" })
vim.keymap.set("v", "<C-g>", ai_avante_explain, { desc = "AI: Avante Explain with buffer content" })
vim.keymap.set("t", "<C-g>", ai_bash, { desc = "AI: Generate Bash Command" })
vim.keymap.set("i", "<C-g>", ai_completion, { desc = "AI: Trigger completion" })
vim.keymap.set("i", "<A-q>", ai_dismiss, { desc = "AI: Dismiss completion" })

vim.keymap.set("v", "<leader>ae", ai_explain, { desc = "AI: Simple Explain just for selected content" })
vim.keymap.set("n", "<leader>ae", ai_explain_function, { desc = "AI: CallGraph Explain" })
vim.keymap.set("v", ",ac", ai_add_context, { desc = "AI: Add Context" })
vim.keymap.set("n", ",ac", ai_clean_context, { desc = "AI: Clean Context" })
