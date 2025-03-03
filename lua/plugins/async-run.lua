local function async_command_to_quickfix(command)
  local qf_entries = {}

  vim.fn.jobstart(command, {
    mode = 'out_err',
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data, _)
      if data then
        for _, chunk in ipairs(data) do -- 遍历 data 数组的每个元素 (chunk)
          for _, line in ipairs(vim.split(chunk, '\n', { trimempty = true })) do -- 对每个 chunk 进行换行分割
            local parts = vim.split(line, ':', { trimempty = true })
            local filename = ''
            local lnum = nil
            local text = line
            if #parts >= 3 then -- 尝试解析 filename, lnum, 和可能的 colnum
              filename = parts[1]
              lnum = tonumber(parts[2])
              text = table.concat(vim.list_slice(parts, 3), ':') -- 剩余部分作为 text, 即使可能为空, 从 parts[3] 开始
              if not lnum then -- 如果 lnum 转换失败，则重置为 nil
                lnum = nil
                text = line -- 整个 line 作为 text
                filename = '' -- filename 也清空，因为解析失败
              end
            elseif #parts == 2 then -- 尝试解析 filename 和 lnum
              filename = parts[1]
              lnum = tonumber(parts[2])
              if not lnum then -- 如果 lnum 转换失败，则整个 line 作为 text
                lnum = nil
                text = line -- 整个 line 作为 text
                filename = '' -- filename 也清空，因为解析失败
              else
                text = '' -- text 为空, 如果 lnum 解析成功，text 应该为空或从上下文中获取
              end
            end

            if filename ~= '' and lnum then
              table.insert(qf_entries, { filename = filename, lnum = lnum, text = text, type = 'I' })
            else
              table.insert(qf_entries, { filename = '', lnum = #qf_entries + 1, text = text, type = 'I' }) -- 如果解析失败，仍然添加整行，但 filename 为空
            end
          end
        end
      end
    end,
    on_stderr = function(_, data, _)
      if data then
        for _, chunk in ipairs(data) do -- 遍历 data 数组的每个元素 (chunk)
          for _, line in ipairs(vim.split(chunk, '\n', { trimempty = true })) do -- 对每个 chunk 进行换行分割
            local parts = vim.split(line, ':', { trimempty = true })
            local filename = ''
            local lnum = nil
            local text = line
            if #parts >= 3 then -- 尝试解析 filename, lnum, 和可能的 colnum
              filename = parts[1]
              lnum = tonumber(parts[2])
              text = table.concat(vim.list_slice(parts, 4), ':') -- 剩余部分作为 text, 即使可能为空
              if not lnum then -- 如果 lnum 转换失败，则重置为 nil
                lnum = nil
                text = line -- 整个 line 作为 text
                filename = '' -- filename 也清空，因为解析失败
              end
            elseif #parts == 2 then -- 尝试解析 filename 和 lnum
              filename = parts[1]
              lnum = tonumber(parts[2])
              text = '' -- text 为空
               if not lnum then -- 如果 lnum 转换失败，则重置为 nil
                lnum = nil
                text = line -- 整个 line 作为 text
                filename = '' -- filename 也清空，因为解析失败
              end
            end

            if filename ~= '' and lnum then
              table.insert(qf_entries, { filename = filename, lnum = lnum, text = text, type = 'E' })
            else
              table.insert(qf_entries, { filename = '', lnum = #qf_entries + 1, text = text, type = 'E' }) -- 如果解析失败，仍然添加整行，但 filename 为空
            end
          end
        end
      end
    end,
    on_exit = function()
      vim.fn.setqflist({}, 'r')
      vim.fn.setqflist(qf_entries, 'a')
      vim.notify('Async command finished, output in quickfix', vim.log.levels.INFO, { title = 'Async Command' })
    end,
  })
end

vim.api.nvim_create_user_command('AsyncRun', function(command_args)
    local command = table.concat(command_args.fargs, ' ')
    async_command_to_quickfix(command)
end, { nargs = '*', desc = 'Run command asynchronously and put output to quickfix' })

-- return {
--   async_command_to_quickfix = async_command_to_quickfix,
-- }

-- Example usage:
-- In your init.lua:

-- vim.keymap.set('n', '<leader>gc', function()
--   async_command_to_quickfix("git status", {notify_success = true})
-- end, { desc = "Git Status to Quickfix" })

-- vim.keymap.set('n', '<leader>ff', function()
--     local pattern = vim.fn.input("Find: ")
--     async_command_to_quickfix("rg --vimgrep " .. vim.shellescape(pattern) .. " .", {notify_success = false})
-- end, { desc = "RipGrep Find to Quickfix"})

-- another example using arguments, also shows more options
-- local function compile_and_check(filename)
--     async_command_to_quickfix(
--         "luacheck " .. vim.shellescape(filename),
--         {
--           notify_success = false,
--         }
--     )
-- end
--
-- vim.api.nvim_create_user_command("CompileCheck", function()
--   compile_and_check(vim.fn.expand("%"))
-- end, { desc = "Run luacheck on current file", nargs = 0 })
