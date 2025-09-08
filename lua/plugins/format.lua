local status, conform = pcall(require, "conform")
if not status then
  vim.notify("Not find plugin conform")
  return
end

conform.setup({
  formatters_by_ft = {
    cpp = { "clang_format" },
    c = { "clang_format" },
    cmake = { "cmake_format" },
    sh = { "shfmt" },
    lua = { "stylua" },
    -- Conform will run multiple formatters sequentially
    python = { "isort", "black" },
    -- You can customize some of the format options for the filetype (:help conform.format)
    rust = { "rustfmt", lsp_format = "fallback" },
    -- Conform will run the first available formatter
    javascript = { "prettierd", "prettier", stop_after_first = true },
    html = { "prettierd", "prettier", stop_after_first = true },
    json = { "jq" },
    -- Use the "_" filetype to run formatters on filetypes that don't
    -- have other formatters configured.
    ["_"] = { "trim_whitespace" },
  },
  -- The options you set here will be merged with the builtin formatters.
  -- You can also define any custom formatters here.
  formatters = {
    clang_format = {
      prepend_args = { "--style=file", "--fallback-style=Google" },
      -- prepend_args = { "--style=file:/home/myname/myproject1/.clang-format" },
    },
  },
  -- format_on_save = {
  -- These options will be passed to conform.format()
  -- timeout_ms = 500,
  -- lsp_format = "fallback",
  -- },
})

vim.api.nvim_create_user_command("Format", function(args)
  local range = nil
  if args.count ~= -1 then
    local end_line = vim.api.nvim_buf_get_lines(0, args.line2 - 1, args.line2, true)[1]
    range = {
      start = { args.line1, 0 },
      ["end"] = { args.line2, end_line:len() },
    }
  end
  require("conform").format({ async = true, lsp_format = "fallback", range = range })
end, { range = true })
