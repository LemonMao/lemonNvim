-- External functions statement
local utils = require("utils")
local ai_path = utils.ai_path
local read_prompt = utils.read_prompt
local AI_prompt = utils.AI_prompt


-- ########################
-- CodeCompanionChat Spinner
-- ########################
local processing = false
local spinner_index = 1
local namespace_id = nil
local timer = nil
local spinner_symbols = {
  "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏",
}
local filetype = "codecompanion"

local function get_buf(ft)
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].filetype == ft then
      return buf
    end
  end
  return nil
end

local function stop_spinner()
  processing = false
  if timer then
    timer:stop()
    timer:close()
    timer = nil
  end

  local buf = get_buf(filetype)
  if buf then
    vim.api.nvim_buf_clear_namespace(buf, namespace_id, 0, -1)
  end
end

local function update_spinner()
  if not processing then
    stop_spinner()
    return
  end

  spinner_index = (spinner_index % #spinner_symbols) + 1

  local buf = get_buf(filetype)
  if buf == nil then
    return
  end

  vim.api.nvim_buf_clear_namespace(buf, namespace_id, 0, -1)

  local last_line = vim.api.nvim_buf_line_count(buf) - 1
  vim.api.nvim_buf_set_extmark(buf, namespace_id, last_line, 0, {
    virt_lines = { { { spinner_symbols[spinner_index] .. " Processing...", "Comment" } } },
    virt_lines_above = true,
  })
end

local function start_spinner()
  processing = true
  spinner_index = 0

  if timer then
    timer:stop()
    timer:close()
  end

  timer = vim.uv.new_timer()
  timer:start(
    0,
    100,
    vim.schedule_wrap(function()
      update_spinner()
    end)
  )
end

local function init()
  namespace_id = vim.api.nvim_create_namespace("CodeCompanionSpinner")

  local group = vim.api.nvim_create_augroup("CodeCompanionHooks", { clear = true })

  vim.api.nvim_create_autocmd({ "User" }, {
    pattern = "CodeCompanionRequest*",
    group = group,
    callback = function(request)
      if request.match == "CodeCompanionRequestStarted" then
        start_spinner()
      elseif request.match == "CodeCompanionRequestFinished" then
        stop_spinner()
      end
    end,
  })
end

-- 在 setup 之前调用初始化函数
init()

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
                        n = { "<CR>", "<C-d>" },
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
                ai_path .. "/agents/cpp_pro.md",
            },
        },
        role_c = {
            description = "A professional C language expert",
            files = {
                ai_path .. "/agents/c_pro.md",
            },
        },
        role_python = {
            description = "A professional Python language expert",
            files = {
                ai_path .. "/agents/python_pro.md",
            },
        },
        role_analyzer = {
            description = "A professional analyzer",
            files = {
                ai_path .. "/agents/analyzer.md",
            },
        },
        role_architect = {
            description = "A professional doc architect",
            files = {
                ai_path .. "/agents/architect.md",
            },
        },
        role_reviewer = {
            description = "A professional reviewer",
            files = {
                ai_path .. "/agents/reviewer.md",
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
            description = "Explain the code with requirements",
            opts = {
                alias = "explain_code",
                auto_submit = false,
                modes = { "v" },
                placement = "new",
                stop_context_insertion = true,
                ignore_system_prompt = true,
                -- intro_message = "Explain the code with requirements",
                is_slash_cmd = false,
                is_workflow = false,
                --[[
                   [ pre_hook = nil,
                   [ rules = nil,
                   [ stop_context_insertion = nil,
                   [ user_prompt = nil,
                   ]]
            },
            prompts = {
                {
                    role = "system",
                    content = function()
                        local principles = read_prompt(ai_path .. "/agents/architect.md")
                        return AI_prompt(principles, nil, true)
                    end,
                },
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
                            behavior = behavior .. "5. The selected code of #{buffer} is:\n" .. selected_code .. "\n"
                        else
                            behavior = behavior .. "3. The current file is #{buffer}\n" .. selected_code .. "\n"
                        end

                        return behavior
                    end,
                },
            },
        },
        ["Modify code"] = {
            interaction = "chat",
            description = "Modify code or implement features with requirements",
            opts = {
                alias = "modify_code",
                auto_submit = false,
                modes = { "v", "n" },
                placement = "new",
                stop_context_insertion = true,
                ignore_system_prompt = true,
                intro_message = "Modify code or implement features with requirements",
                is_slash_cmd = false,
                is_workflow = false,
            },
            prompts = {
                {
                    role = "system",
                    content = function()
                        local principles = read_prompt(ai_path .. "/agents/developer.md")
                        return AI_prompt(principles, nil, true)
                    end,
                },
                {
                    role = "user",
                    content = function(context)
                        local behavior = "1. If code is selected, focus on modifying or completing that specific block. If no code is selected, implement the requested feature by modifying all relevant files in the context.\n" ..
                        "2. You must strictly provide the response in the following format:\n" ..
                        "### Code Change\n" ..
                        "[The modified or new code. Use necessary in-line English comments.]\n" ..
                        "### Explaination\n" ..
                        "[A detail summary of the changes, benefits, and potential trade-offs.]\n" ..
                        "3. If you don't find any useful requirements to implement the code, ask for it\n" ..
                        "4. Use @{insert_edit_into_file} to apply the change.\n"..

                        if context.is_visual then
                            local selected_code = utils.wrap_code_with_md(context.code, context.filetype)
                            behavior = behavior .. "5. The selected code of #{buffer} is:\n" .. selected_code .. "\n"
                        else
                            behavior = behavior .. "5. The current file is #{buffer}\n" .. selected_code .. "\n"
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
                stop_context_insertion = true,
                ignore_system_prompt = true,
                is_slash_cmd = false,
                is_workflow = false,
            },
            prompts = {
                {
                    role = "system",
                    content = function()
                        local principles = read_prompt(ai_path .. "/agents/reviewer.md")
                        return AI_prompt(principles, nil, true)
                    end,
                },
                {
                    role = "user",
                    content = function(context)
                        local behavior = "1. If user provides the selected code, just review this part code don't touch others\n" ..
                        "2. If user doesn't provide the selected code, review all the files\n"

                        if context.is_visual then
                            local selected_code = utils.wrap_code_with_md(context.code, context.filetype)
                            behavior = behavior .. "5. The selected code of #{buffer} is:\n" .. selected_code .. "\n"
                        else
                            behavior = behavior .. "5. The current file is #{buffer}\n" .. selected_code .. "\n"
                        end

                        behavior = behavior .. "\nUser requirements:\n"
                        return behavior
                    end,
                },
            },
        },
    },
    extensions = {
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
-- slash_commands: Insert customer prompt in current session.
