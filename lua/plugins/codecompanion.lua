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
-- Usage:
-- You can run :checkhealth codecompanion to verify that all requirements are met.
-- How to delete the context? Just delete it in blockquote.
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
            inline = {
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
    extensions = {
        history = {
            enabled = true,
            opts = {
                -- Keymap to open history from chat buffer (default: gh)
                keymap = "gh",
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
