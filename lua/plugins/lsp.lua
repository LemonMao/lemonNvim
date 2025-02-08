-- mason.lua
local mason_status, mason = pcall(require, "mason")
if not mason_status then
  vim.notify("Not find plugin mason")
  return
end

local nlsp_status, nvim_lsp = pcall(require, "lspconfig")
if not nlsp_status then
  vim.notify("Not find plugin lspconfig")
  return
end

local mlsp_status, mason_lspconfig = pcall(require, "mason-lspconfig")
if not mlsp_status then
  vim.notify("Not find plugin mason-lspconfig")
  return
end

local lsp_capabilities = require('cmp_nvim_lsp').default_capabilities()

function LspKeybind(client, bufnr)
 local function buf_set_keymap(...)
  vim.api.nvim_buf_set_keymap(bufnr, ...)
 end
  require("keybindings").lspKeybinding(buf_set_keymap)
end

mason.setup({
  ui = {
    icons = {
      package_pending = " ",
      package_installed = " ",
      package_uninstalled = " ",
    },
  },

  log_level = vim.log.levels.INFO,
  max_concurrent_installers = 10,
})
mason_lspconfig.setup({
  -- A list of servers to automatically install if they're not already installed.
  -- This setting has no relation with the `automatic_installation` setting.
  ensure_installed = { "lua_ls", "clangd", "pylsp"},
  automatic_installation = true,
})


nvim_lsp.lua_ls.setup({
  capabilities = lsp_capabilities,
  on_attach = LspKeybind,
  on_init = function(client)
    local path = client.workspace_folders[1].name
    if not vim.loop.fs_stat(path .. "/.luarc.json") and not vim.loop.fs_stat(path .. "/.luarc.jsonc") then
      client.config.settings = vim.tbl_deep_extend("force", client.config.settings, {
        Lua = {
          runtime = {
            version = "LuaJIT",
          },
          workspace = {
            checkThirdParty = false,
            library = {
              vim.env.VIMRUNTIME,
            },
          },
        },
      })

      client.notify("workspace/didChangeConfiguration", { settings = client.config.settings })
    end
    return true
  end,
})

nvim_lsp.pylsp.setup{
  capabilities = lsp_capabilities,
  on_attach = LspKeybind,
  settings = {
    pylsp = {
      plugins = {
        pycodestyle = {
          ignore = {'W391'},
          maxLineLength = 100
        }
      }
    }
  }
}

nvim_lsp.clangd.setup{
  capabilities = lsp_capabilities,
  on_attach = LspKeybind,
  mason = false,
  cmd = {
    'clangd',
    '--all-scopes-completion',
  },
}

-- clangd-extenstion
require("clangd_extensions").setup()
