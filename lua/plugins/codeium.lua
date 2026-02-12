-- ## ------------------------------ ##
-- ## AI Codeium
-- ## ------------------------------ ##
--
-- The plugin log is written to ~/.cache/nvim/codeium/codeium.log.
-- You can set the logging level to one of "trace/debug/info/warn/error"
-- by exporting the `DEBUG_CODEIUM` environment variable.
--
codeiumOpts = {
    -- Optionally disable cmp source if using virtual text only
    enable_cmp_source = false,
    enable_chat = false,

    -- remove if not use enterprise_mode
    --[[
       [ enterprise_mode = true,
       [ api = {
       [     -- the hostname. Example: "codeium.example.com". Required when using enterprise mode
       [     host = "codeium.delllabs.net",
       [     -- the port. Defaults to 443
       [     port = 443,
       [     -- the path prefix to the API server. Default for enterprise: "/_route/api_server"
       [     path = "/_route/api_server",
       [     -- the portal URL to use (for enterprise mode). Defaults to host:port
       [     portal_url = nil,
       [ },
       ]]

    virtual_text = {
        enabled = true,

        -- These are the defaults

        -- Set to true if you never want completions to be shown automatically.
        manual = true,
        -- A mapping of filetype to true or false, to enable virtual text.
        filetypes = {},
        -- Whether to enable virtual text of not for filetypes not specifically listed above.
        default_filetype_enabled = true,
        -- filetypes = {
        --     python = true,
        --     markdown = false
        -- },
        -- default_filetype_enabled = true,

        -- How long to wait (in ms) before requesting completions after typing stops.
        idle_delay = 300,
        -- Priority of the virtual text. This usually ensures that the completions appear on top of
        -- other plugins that also add virtual text, such as LSP inlay hints, but can be modified if
        -- desired.
        virtual_text_priority = 65535,
        -- Set to false to disable all key bindings for managing completions.
        map_keys = true,
        -- The key to press when hitting the accept keybinding but no completion is showing.
        -- Defaults to \t normally or <c-n> when a popup is showing.
        accept_fallback = nil,
        -- Key bindings for managing completions in virtual text mode.
        key_bindings = {
            -- Accept the current completion.
            accept = "<Tab>",
            -- Accept the next word.
            accept_word = false,
            -- Accept the next line.
            accept_line = false,
            -- Clear the virtual text.
            clear = "<S-Tab>",
            -- Cycle to the next completion.
            next = "<M-]>",
            -- Cycle to the previous completion.
            prev = "<M-[>",
        }
    },
    workspace_root = {
        use_lsp = true,
        find_root = nil,
        paths = {
            ".git",
            ".svn",
            ".root",
        },
    },
}

-- Initialize Codeium plugin with configuration
require("codeium").setup(codeiumOpts)

-- Set up statusbar refresh for lualine integration
require('codeium.virtual_text').set_statusbar_refresh(function()
    require('lualine').refresh()
end)
