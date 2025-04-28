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

local ensure_mason_packages = {
    -- formater
    "clang-format",
    "stylua",
    "black",
    -- linter
    "codespell",
}

vim.api.nvim_create_user_command("MasonEnsurePackages", function()
    local mr = require("mason-registry")
    local installed_any = false

    for _, pkg_name in ipairs(ensure_mason_packages) do
        local pkg = mr.get_package(pkg_name)
        if not pkg:is_installed() then
            installed_any = true
            print("Mason: Installing " .. pkg_name .. "...")
            -- Asynchronous installation, does not block Neovim
            pkg:install():on("closed", function()
                -- Optional: Callback after installation is complete
                vim.schedule(function()
                    print("Mason: Successfully installed " .. pkg_name)
                end)
            end)
        end
    end

    if not installed_any then
        print("Mason: All specified packages are already installed.")
    end
end, {})

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

  -- A list of packages to ensure are installed. Mason will install these
  -- automatically if they are not already installed.
  ensure_installed = {
    -- Formatters
    "clang-format",
  },
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

-- if want to make clangd to support c++20, create .clangd and add:
-- CompileFlags:
--   Add: [-std=c++20]
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
