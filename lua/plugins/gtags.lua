require("cscope_maps").setup({
  -- maps related defaults
  disable_maps = true, -- "true" disables default keymaps
  skip_input_prompt = false, -- "true" doesn't ask for input
  prefix = "<leader>s", -- prefix to trigger maps

  -- cscope related defaults
  cscope = {
    -- db_path = "/home/lemon/.cache/tags/home-lemon-project-leveldb",
    -- DB or table of DBs
    -- location of cscope db file
    db_file = "./cscope.out", -- DB or table of DBs
                              -- NOTE:
                              --   when table of DBs is provided -
                              --   first DB is "primary" and others are "secondary"
                              --   primary DB is used for build and project_rooter
    -- cscope executable
    exec = "gtags-cscope", -- "cscope" or "gtags-cscope"
    -- choose your fav picker
    picker = "quickfix", -- "quickfix", "telescope", "fzf-lua" or "mini-pick"
    -- size of quickfix window
    qf_window_size = 10, -- any positive integer
    -- position of quickfix window
    qf_window_pos = "bottom", -- "bottom", "right", "left" or "top"
    -- "true" does not open picker for single result, just JUMP
    skip_picker_for_single_result = true, -- "false" or "true"
    -- custom script can be used for db build
    db_build_cmd = { script = "default", args = { "-bqkv" } },
    -- statusline indicator, default is cscope executable
    statusline_indicator = nil,
    -- try to locate db_file in parent dir(s)
    project_rooter = {
      enable = false, -- "true" or "false"
      -- change cwd to where db_file is located
      change_cwd = false, -- "true" or "false"
    },
  },

  -- stack view defaults
  stack_view = {
    tree_hl = true, -- toggle tree highlighting
  }
})

-- ############
-- ## Functions
-- ############
-- Function: copy GTAGS to project PWD
function CopyGtagsFromCache()
    -- 获取当前工作目录和缓存目录配置
    local pwd = vim.fn.getcwd()
    local cache_dir = vim.fn.expand(vim.g.gutentags_cache_dir)

    -- 生成缓存子目录名（将路径斜杠转换为连字符）
    local cache_subdir = pwd:gsub("^/", ""):gsub("/", "-")
    local source_dir = cache_dir .. "/" .. cache_subdir

    -- 检查标记文件是否存在
    local has_marker = false
    for _, marker in ipairs(vim.g.gutentags_project_root) do
        if vim.fn.filereadable(pwd .. "/" .. marker) == 1 then
            has_marker = true
            break
        end
    end

    if not has_marker then return end

    -- 检查缓存目录是否存在
    if vim.fn.isdirectory(source_dir) ~= 1 then
        print("Cache directory not found: " .. source_dir)
        return
    end

    -- 获取所有 G 开头的文件
    local files = vim.fn.globpath(source_dir, "G*", false, true)
    if #files == 0 then
        print("No G* files found in: " .. source_dir)
        return
    end

    -- 执行复制操作
    for _, file in ipairs(files) do
        local cmd = string.format(
            "cp -f %s %s",
            vim.fn.shellescape(file),
            vim.fn.shellescape(pwd)
        )
        os.execute(cmd)
    end

    print(string.format("Copied %d GTAGS files to %s", #files, pwd))
end

-- Function:  to check if GTAGS file exists in the current PWD and run the gtags command
function UpdateGtagsIncrementally()
  -- Get the current working directory
  local cwd = vim.fn.getcwd()

  -- Check if GTAGS file exists in the current directory
  local gtags_file = cwd .. '/GTAGS'
  if vim.fn.filereadable(gtags_file) == 1 then
    -- Define the gtags command
    local cmd = 'gtags --incremental --skip-unreadable ' .. cwd

    -- Run the command asynchronously
    local handle
    local stdout = vim.loop.new_pipe(false)
    local stderr = vim.loop.new_pipe(false)

    handle = vim.loop.spawn('sh', {
      args = {'-c', cmd},
      stdio = {nil, stdout, stderr},
    }, function(code, signal)
      vim.schedule(function()
        if code == 0 then
          vim.notify('Successfully updated GTAGS incrementally in ' .. cwd)
        else
          vim.notify('Failed to update GTAGS in ' .. cwd .. ' with code ' .. code, vim.log.levels.ERROR)
        end
      end)

      -- Cleanup
      handle:close()
      stdout:close()
      stderr:close()
    end)

    -- Capture stdout and stderr (optional)
    vim.loop.read_start(stdout, function(err, data)
      assert(not err, err)
      if data then
        vim.schedule(function()
          vim.api.nvim_out_write(data)
        end)
      end
    end)

    vim.loop.read_start(stderr, function(err, data)
      assert(not err, err)
      if data then
        vim.schedule(function()
          vim.api.nvim_err_write(data)
        end)
      end
    end)

  else
    vim.notify('GTAGS file not found in ' .. cwd, vim.log.levels.WARN)
  end
end

-- ############
-- ## Gtags Copy/Update commands
-- ############
-- copy GTAGS to project PWD
vim.api.nvim_create_user_command("GtagsCopy", function()
    vim.loop.new_thread(function()
        CopyGtagsFromCache()
    end)
end, {nargs = 0})

-- Incrementally update project GTAGS
vim.api.nvim_create_user_command('GtagsUpdate', function()
  UpdateGtagsIncrementally()
end, { nargs = 0 })
