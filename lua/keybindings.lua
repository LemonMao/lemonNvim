-- vim.api.nvim_set_keymap('模式', '按键', '映射为', 'options')
-- options: { noremap = true, silent = true }。noremap 表示不会重新映射, silent 为 true，表示不会输出多余的信息。
--

-- local map = vim.api.nvim_set_keymap
local function map(mode, lhs, rhs, opts)
    -- Ensure opts is a table if not provided
    opts = opts or {}

    -- Set default values for opts
    opts.noremap = opts.remap == nil and true or not opts.remap
    opts.silent = opts.silent == nil and true or opts.silent

    -- Set the keymap
    vim.keymap.set(mode, lhs, rhs, opts)
end

-- 插件快捷键
local pluginKeys = {}

map("n", "s", "", { desc = "Undo s key" })

-- ## -------------------------------------- ##
-- ## Functions
-- ## -------------------------------------- ##
-- Close window
local function toggle_quickfix()
  local has_quickfix = false
  for _, win in ipairs(vim.fn.getwininfo()) do
    if win.quickfix == 1 then
      has_quickfix = true
      break
    end
  end
  if has_quickfix then
    vim.cmd('cclose')
  else
    vim.cmd('copen')
  end
end

local function replace_text_in_cursor()
    local mode = vim.fn.mode()
    local text = ""
    local start_line = 1
    local end_line = vim.fn.line('$')

    if mode == 'n' then
        text = vim.fn.expand('<cword>')
    elseif mode == 'v' or mode == 'V' then
        vim.cmd('silent normal! "xy')
        text = vim.fn.getreg('x')
    end

    local escaped_text = vim.fn.escape(text, '/\\')
    local replace_with = vim.fn.input("Replace '" .. text .. "' with: ")
    local lines_range = vim.fn.input("Lines to replace (default: all): ", start_line .. "," .. end_line)

    -- If user pressed enter without input, use default range
    if lines_range == "" then
        lines_range = "1,$"
    end

    -- Get current cursor position
    local pos = vim.api.nvim_win_get_cursor(0)

    -- Execute the substitution
    vim.cmd(lines_range .. 's/\\V' .. escaped_text .. '\\m/' .. replace_with .. '/g')

    -- Restore cursor position
    vim.api.nvim_win_set_cursor(0, pos)
end

local function copy_path_to_clip()
    local current_file = vim.api.nvim_buf_get_name(0)
    if vim.fn.empty(current_file) == 1 then
        vim.notify("No file in current buffer", vim.log.levels.WARN, { title = "Copy Relative Dir Path" })
        return
    end

    local current_dir = vim.fn.fnamemodify(current_file, ":h")
    local absolute_filepath = vim.fn.fnamemodify(current_file, ":p") -- ":p" gets the absolute path

    vim.cmd('let @+ = expand("' .. absolute_filepath .. '")')
    vim.notify("Absolute file path copied to clipboard:\n" .. absolute_filepath, vim.log.levels.INFO, { title = "Copy Absolute File Path" })
end

local function search_string_in_directory()
    local current_file = vim.api.nvim_buf_get_name(0)
    local search_dir

    if vim.fn.empty(current_file) == 1 then
        vim.notify("No file associated with the current buffer. Grepping PWD.", vim.log.levels.WARN, { title = "Live Grep Dir" })
        require('telescope.builtin').live_grep()
        return
    end

    local current_dir = vim.fn.fnamemodify(current_file, ":h")

    -- Prompt the user, pre-filling with the current directory and offering directory completion
    local user_input_dir = vim.fn.input("Search directory: ", current_dir, "dir")

    -- Check if user cancelled (pressed Esc or <C-c>)
    if user_input_dir == nil then
        vim.notify("Search cancelled.", vim.log.levels.INFO, { title = "Live Grep Dir" })
        return
    end

    -- Check if user provided an empty path (e.g., deleted everything and pressed Enter)
    if vim.fn.empty(user_input_dir) == 1 then
        vim.notify("No directory provided.", vim.log.levels.WARN, { title = "Live Grep Dir" })
        return
    end

    search_dir = user_input_dir

    -- Ensure the chosen directory exists before searching
    if vim.fn.isdirectory(search_dir) == 1 then
        require('telescope.builtin').live_grep({ search_dirs = { search_dir } })
    else
        vim.notify("Directory not found or invalid: " .. search_dir, vim.log.levels.ERROR, { title = "Live Grep Dir" })
        -- Optionally, you could fall back to PWD grep here if desired:
        -- require('telescope.builtin').live_grep()
    end
end

local function close_empty_and_current_buffers()
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_get_name(buf) == "" and buf ~= vim.api.nvim_get_current_buf() then
            vim.api.nvim_buf_delete(buf, {force = true})
        end
    end
    vim.cmd("bdelete!")
end

local function close_preview_window()
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        local buf_name = vim.api.nvim_buf_get_name(buf)
        if vim.api.nvim_buf_is_valid(buf) and (buf_name == "" or buf_name:find("NvimTree")) and buf ~= vim.api.nvim_get_current_buf() then
            vim.api.nvim_buf_delete(buf, {force = true})
        end
    end
    vim.cmd("PreviewClose")
end

--[[
-- TODO: remove them later
   [ local function search_cursor_string_in_current_buffer()
   [     local current_file = vim.api.nvim_buf_get_name(0)
   [     if vim.fn.empty(current_file) == 1 then
   [         vim.notify("No file in current buffer to search.", vim.log.levels.WARN, { title = "Telescope Grep Current Buffer" })
   [         return
   [     end
   [     -- telescope.builtin.grep_string automatically uses the word under the cursor
   [     require('telescope.builtin').grep_string({ search_dirs = { current_file } })
   [ end
   [
   [ -- New function to search string under cursor in the current buffer's directory
   [ local function search_cursor_string_in_current_buffer_directory()
   [     local current_file = vim.api.nvim_buf_get_name(0)
   [     if vim.fn.empty(current_file) == 1 then
   [         vim.notify("No file in current buffer. Searching in PWD.", vim.log.levels.WARN, { title = "Telescope Grep CWD" })
   [         require('telescope.builtin').grep_string() -- Fallback to PWD
   [         return
   [     end
   [
   [     local buffer_dir = vim.fn.fnamemodify(current_file, ":h")
   [     if vim.fn.empty(buffer_dir) == 1 then
   [         vim.notify("Could not determine buffer directory. Searching in PWD.", vim.log.levels.WARN, { title = "Telescope Grep CWD" })
   [         require('telescope.builtin').grep_string() -- Fallback to PWD
   [         return
   [     end
   [
   [     if vim.fn.isdirectory(buffer_dir) == 0 then
   [         vim.notify("Directory not found or invalid: " .. buffer_dir .. ". Searching in PWD.", vim.log.levels.WARN, { title = "Telescope Grep CWD" })
   [         require('telescope.builtin').grep_string() -- Fallback to PWD
   [         return
   [     end
   [
   [     require('telescope.builtin').grep_string({ cwd = buffer_dir })
   [ end
   ]]

-- Unified function for Telescope searches
-- search_type: 'live_grep' (for user input) or 'grep_string' (for word under cursor)
-- scope_type: 'pwd', 'buffer_dir', 'prompt_dir', 'current_buffer', 'open_files'
local function do_telescope_search(search_type, scope_type)
    local telescope_opts = {}
    local current_file = vim.api.nvim_buf_get_name(0)
    local has_file = (vim.fn.empty(current_file) == 0)
    local search_query = ""

    -- Determine search_query based on current mode
    local current_mode = vim.fn.mode()
    if current_mode == 'v' or current_mode == 'V' or current_mode == '\22' then
        -- Save current register and visual selection
        local saved_register = vim.fn.getreg('"')
        local saved_register_type = vim.fn.getregtype('"')

        -- Yank the visual selection
        vim.cmd('silent normal! y')

        -- Get the yanked text
        search_query = vim.fn.getreg('"')

        -- Restore register
        vim.fn.setreg('"', saved_register, saved_register_type)

        if search_query == "" then
            vim.notify("No text selected for search.", vim.log.levels.WARN, { title = "Telescope Search" })
            return
        end

        -- Remove trailing newline if present
        search_query = search_query:gsub('\n$', '')
    end

    if scope_type == 'buffer_dir' then
        local buffer_dir = ""
        if has_file then
            buffer_dir = vim.fn.fnamemodify(current_file, ":h")
        end

        if vim.fn.empty(buffer_dir) == 1 or vim.fn.isdirectory(buffer_dir) == 0 then
            vim.notify("Could not determine valid buffer directory. Searching in PWD.", vim.log.levels.WARN, { title = "Telescope Search" })
            -- Fallback to PWD (telescope_opts remains empty)
        else
            telescope_opts.cwd = buffer_dir
        end
    elseif scope_type == 'prompt_dir' then
        local initial_dir = has_file and vim.fn.fnamemodify(current_file, ":h") or vim.fn.getcwd()
        local user_input_dir = vim.fn.input("Search directory: ", initial_dir, "dir")

        if user_input_dir == nil then
            vim.notify("Search cancelled.", vim.log.levels.INFO, { title = "Telescope Search" })
            return
        end
        if vim.fn.empty(user_input_dir) == 1 or vim.fn.isdirectory(user_input_dir) == 0 then
            vim.notify("Invalid or empty directory provided. Searching in PWD.", vim.log.levels.WARN, { title = "Telescope Search" })
            -- Fallback to PWD
        else
            telescope_opts.cwd = user_input_dir
        end
    elseif scope_type == 'open_files' then
        telescope_opts.grep_open_files = true
    elseif scope_type == 'current_buffer' then
        if not has_file then
            vim.notify("No file in current buffer to search.", vim.log.levels.WARN, { title = "Telescope Search" })
            return
        end
        telescope_opts.search_dirs = { current_file }
    end
    -- If scope_type is 'pwd', telescope_opts remains empty, defaulting to PWD.

    -- Add the determined search query to the telescope options
    if search_query ~= "" then
        telescope_opts.search = search_query
    end

    if search_type == 'live_grep' then
        if scope_type == 'current_buffer' then
            require('telescope.builtin').current_buffer_fuzzy_find()
        else
            require('telescope.builtin').live_grep(telescope_opts)
        end
    elseif search_type == 'grep_string' then
        require('telescope.builtin').grep_string(telescope_opts)
    else
        vim.notify("Invalid search type provided.", vim.log.levels.ERROR, { title = "Telescope Search" })
    end
end

-- Function to search man pages with word under cursor
local function search_man_pages_with_cursor_word()
    local word = vim.fn.expand('<cword>')
    -- Copy to system clipboard
    vim.fn.setreg('+', word)
    -- Open Telescope man_pages with the word as default text
    require('telescope.builtin').man_pages({ sections = {'ALL'}, default_text = word })
end

-- Function to toggle multiple buffer groups
local function toggle_multiple_buffer_groups()
    vim.cmd('BufferLineGroupToggle Term')
    vim.cmd('BufferLineGroupToggle Docs')
    vim.cmd('BufferLineGroupToggle Logs')
end

-- ## -------------------------------------- ##
-- ## F1 ~~ F12 Hotkeys
-- ## -------------------------------------- ##
map("n", "<F1>", ":Dashboard<CR>", { desc = "Dashboard" })
map("n", "<F2>", ":Telescope projects<CR>", { desc = "Telescope projects" })
-- Enhanced F3 keybinding for different modes
-- map('n', '<F3>', ":1,$s/\<<C-R><C-W>\>//g", { desc = "Replace all" })
map({'n','x'}, '<F3>', replace_text_in_cursor, { desc = "Replace current cursor text" })
map("n", "<F9>", ":Cscope find g ", { desc = "Gtags: find references" })

-- ## ------------------------------ ##
-- ## Windows Hotkeys
-- ## Moving/Switch/Paging/Zooming/Split
-- ## ------------------------------ ##
-- map("n", "sv", ":vsp<CR>", { desc = "" })
-- map("n", "sh", ":sp<CR>", { desc = "" })
map("n", "<C-h>", "<C-w>h", {desc = "Jump to left windown"})
map("n", "<C-j>", "<C-w>j", {desc = "Jump to down windown"})
map("n", "<C-k>", "<C-w>k", {desc = "Jump to up windown"})
map("n", "<C-l>", "<C-w>l", {desc = "Jump to right windown"})
map("n", "<C-Left>", ":vertical resize -19<CR>", { desc = "Reduce vertical windown size" })
map("n", "<C-Right>", ":vertical resize +19<CR>", { desc = "Enlarge vertical windown size" })
map("n", "<C-Down>", ":resize -10<CR>", { desc = "Reduce horizonal windown size" })
map("n", "<C-Up>", ":resize +10<CR>", { desc = "Enlarge horizonal windown size" })
map("n", "<leader>q", ":q<CR>", { desc = "Close the current window" })
map('n', '<A-q>', toggle_quickfix, { desc = "Toggle quickfix window" })
map({'n', 't', 'v'}, "<A-c>", close_preview_window, { desc = "Bufferline: Close preview window"})
-- 等比例 <C-w> =
-- 关当前窗口 <C-w>c
map("v", "<", "<gv", { desc = "Visual indent" })
map("v", ">", ">gv", { desc = "Visual indent" })
map("v", "J", ":move '>+1<CR>gv-gv", { desc = "Move selected text down" })
map("v", "K", ":move '<-2<CR>gv-gv", { desc = "Move selected text up" })
-- Bufferline
map("n", "<A-h>", ":BufferLineCyclePrev<CR>", { desc = "Bufferline: Switch to previous buffer"})
map("t", "<A-h>", "<C-\\><C-n>:BufferLineCyclePrev<CR>", { desc = "Bufferline: Switch to previous buffer"})
map("n", "<A-l>", ":BufferLineCycleNext<CR>", { desc = "Bufferline: Switch to next buffer"})
map("t", "<A-l>", "<C-\\><C-n>:BufferLineCycleNext<CR>", { desc = "Bufferline: Switch to next buffer"})
map({'n', 't', 'v'}, '<A-r>', '<C-\\><C-n>:BufferLineMoveNext<CR>:BufferLineMovePrev<CR>', { desc = "Bufferline: Refresh senquence"})
map({'n', 't', 'v'}, "<A-n>", "<C-\\><C-n>:BufferLineMoveNext<CR>", { desc = "Bufferline: Move current buffer to next location"})
map({'n', 't', 'v'}, "<A-p>", "<C-\\><C-n>:BufferLineMovePrev<CR>", { desc = "Bufferline: Move current buffer to previous location"})
map({'n', 't', 'v'}, '<A-N>', '<C-\\><C-n>:lua require\'bufferline\'.move_to(-1)<CR>', { desc = "Bufferline: Move current buffer to last location"})
map({'n', 't', 'v'}, '<A-P>', '<C-\\><C-n>:lua require\'bufferline\'.move_to(1)<CR>', { desc = "Bufferline: Move current buffer to first location"})
map({'n', 't', 'v'}, "<A-w>", close_empty_and_current_buffers, { desc = "Bufferline: Close empty buffers"})
map({'n', 't', 'v'}, '<A-T>', toggle_multiple_buffer_groups, { desc = "Bufferline: Toggle Term, Docs, and Logs groups"})
map({'n', 't', 'v'}, "<A-e>", "<C-\\><C-n>:b# <CR>", { desc = "Bufferline: Switch to recent buffer" })
map({'n', 't', 'v'}, '<A-1>', '<C-\\><C-n><Cmd>BufferLineGoToBuffer 1<CR>', { desc = "Bufferline: Switch to buffer with number"})
map({'n', 't', 'v'}, '<A-2>', '<C-\\><C-n><Cmd>BufferLineGoToBuffer 2<CR>', { desc = "Bufferline: Switch to buffer with number"})
map({'n', 't', 'v'}, '<A-3>', '<C-\\><C-n><Cmd>BufferLineGoToBuffer 3<CR>', { desc = "Bufferline: Switch to buffer with number"})
map({'n', 't', 'v'}, '<A-4>', '<C-\\><C-n><Cmd>BufferLineGoToBuffer 4<CR>', { desc = "Bufferline: Switch to buffer with number"})
map({'n', 't', 'v'}, '<A-5>', '<C-\\><C-n><Cmd>BufferLineGoToBuffer 5<CR>', { desc = "Bufferline: Switch to buffer with number"})
map({'n', 't', 'v'}, '<A-6>', '<C-\\><C-n><Cmd>BufferLineGoToBuffer 6<CR>', { desc = "Bufferline: Switch to buffer with number"})
map({'n', 't', 'v'}, '<A-7>', '<C-\\><C-n><Cmd>BufferLineGoToBuffer 7<CR>', { desc = "Bufferline: Switch to buffer with number"})
map({'n', 't', 'v'}, '<A-8>', '<C-\\><C-n><Cmd>BufferLineGoToBuffer 8<CR>', { desc = "Bufferline: Switch to buffer with number"})
map({'n', 't', 'v'}, '<A-9>', '<C-\\><C-n><Cmd>BufferLineGoToBuffer 9<CR>', { desc = "Bufferline: Switch to buffer with number"})
-- Terminal
map('t', '<Esc>', '<C-\\><C-n>', { desc = "Exit terminal mode" })
-- map("t", "<C-h>", "<C-\\><C-n><C-w>h", {desc = "Jump to left windown from terminal windown"})
map("t", "<C-u>", "<C-\\><C-n><C-u>", { desc = "Exit terminal mode and scroll up page"})
-- map("t", "<C-l>", "<C-\\><C-n><C-w>l", {desc = "Jump to left windown from terminal windown"})
map({'n', 't', 'v'}, '<leader>tv', '<C-\\><C-n><Cmd>vsp | terminal<CR>', { desc = "Open terminal in vertical split" })
map({'n', 't', 'v'}, '<leader>te', '<C-\\><C-n><Cmd>terminal<CR><Cmd>BufferLineMovePrev<CR><Cmd>BufferLineMoveNext<CR>', { desc = "Open terminal in vertical split" })

-- ## ------------------------------ ##
-- ## AI
-- ## ------------------------------ ##
-- Avante
-- map({ "n", "v" }, "<leader>aa", ":AvanteAsk <CR>", { desc = "open dir tree" })
map("n", "<leader>al", ":AvanteClear<CR>", { desc = "Avante: Clear the chat box content" })
map("n", "<A-a>", ":AvanteToggle<CR>", { desc = "Avante: Toggle sidebar" })
map("i", "<A-a>", "<Esc>:AvanteToggle <CR>", { desc = "Avante: Toggle sidebar" })
map('n', '<leader>cmm', ':lua require("codeium").set_option("virtual_text.manual", true)<CR>', { desc = 'Codeium Manual Mode On' })

-- ## ------------------------------ ##
-- ## UI
-- ## ------------------------------ ##
--
-- directory tree, nvim-tree
map("n", "<leader>f", ":NvimTreeToggle<CR>", { desc = "open dir tree" })
map("n", "<leader>F", ":NvimTreeFindFile<CR>", { desc = "open dir tree for file" })
-- Noice
map("n", "<leader>nl", ":Noice last<CR>", { desc = "Noice: Last message" })
map("n", "<leader>nh", ":Noice history<CR>", { desc = "Noice: Shows the message history" })
-- map("n", "<M-n>", ":Noice dismiss<CR>", { desc = "Noice: Dismiss all visible messages" })
-- Readable
map("x", "<leader>ow", ":set wrap!<CR>", { desc = "Toggle line wrapping" })

-- ## Search
-- ## ------------------------------ ##
-- Telescope, find files/global grep
map("n", "sc", ":Telescope ", { desc = "Telescope: Type telescope command" })
map("n", "sf", ":Telescope find_files<CR>", { desc = "Telescope: Search for files in PWD" })
map("n", "sb", ":Telescope buffers<CR>", { desc = "Telescope: Lists open buffers" })
map("n", "sm", ":Telescope oldfiles<CR>", { desc = "Telescope: Lists previously open files" })
map("n", "st", ":Telescope treesitter<CR>", { desc = "Telescope: Lists function names, variables, and other symbols from treesitter queries" })
map("n", "sh", search_man_pages_with_cursor_word, { desc = "Telescope: Search man pages for word under cursor" })
map("n", "sk", ":Telescope keymaps <CR>", { desc = "Telescope: Lists manpage entries" })
-- grep xxx string from xxx
map("n", "sg",  function() do_telescope_search('live_grep', 'current_buffer') end, { desc = "Telescope: Search string in current buffer" })
map("n", "sgf", function() do_telescope_search('live_grep', 'open_files') end, { desc = "Telescope: Search string in the open buffers" })
map("n", "sgd", function() do_telescope_search('live_grep', 'prompt_dir') end, { desc = "Telescope: Search string in directory" })
map("n", "sgg", function() do_telescope_search('live_grep', 'pwd') end, { desc = "Telescope: Search string in your PWD" })
-- search cursor string from xxx
map({"n", "x"}, "ss",  function() do_telescope_search('grep_string', 'current_buffer') end, { desc = "Telescope: Search string under cursor in current buffer" })
map({"n", "x"}, "ssf", function() do_telescope_search('grep_string', 'open_files') end, { desc = "Telescope: Search string under cursor in open buffers" })
map({"n", "x"}, "ssd", function() do_telescope_search('grep_string', 'prompt_dir') end, { desc = "Telescope: Search string under cursor in directory" })
map({"n", "x"}, "ssg", function() do_telescope_search('grep_string', 'pwd') end, { desc = "Telescope: Searches for the string under your cursor in your PWD" })

-- Telescope 列表中 插入模式快捷键
local open_with_trouble = require("trouble.sources.telescope").open
-- Use this to add more results without clearing the trouble list
-- local add_to_trouble = require("trouble.sources.telescope").add

pluginKeys.telescopeList = {
    i = {
        -- 上下移动
        ["<C-j>"] = "move_selection_next",
        ["<C-k>"] = "move_selection_previous",
        ["<Down>"] = "move_selection_next",
        ["<Up>"] = "move_selection_previous",
        -- 历史记录
        ["<C-n>"] = "cycle_history_next",
        ["<C-p>"] = "cycle_history_prev",
        -- 关闭窗口
        ["<C-c>"] = "close",
        -- 预览窗口上下滚动
        ["<A-u>"] = "preview_scrolling_up",
        ["<A-d>"] = "preview_scrolling_down",
        ["g?"] = "which_key",
        ["<C-x>"] = "delete_buffer",
        ["<ESC>"] = "close",
        ["<c-t>"] = open_with_trouble,
    },
    n = { ["<c-t>"] = open_with_trouble },
}

-- ## ------------------------------ ##
-- ## LSP
-- ## ------------------------------ ##
--
-- lsp 快捷键设置
pluginKeys.lspKeybinding = function(mapbuf)
  mapbuf("x", "gn", ":lua vim.lsp.buf.rename()<CR>", { desc = "LSP rename" })
  mapbuf("n", "ga", ":lua vim.lsp.buf.code_action()<CR>", { desc = "LSP code action" })
  mapbuf("n", "gd", ":lua vim.lsp.buf.definition()<CR>", { desc = "LSP goto definition" })
  mapbuf("n", "gh", ":lua vim.lsp.buf.hover()<CR>", { desc = "LSP goto hover" })
  mapbuf("n", "gr", ":lua vim.lsp.buf.references()<CR>", { desc = "LSP goto reference" })
  -- format
  -- mapbuf("n", "<leader>=", ":lua vim.lsp.buf.format { async = true }<CR>", { desc = "" })
end
map('n', 'gs', ':ClangdSwitchSourceHeader<CR>', { desc = "LSP switch source header" })

-- ## ------------------------------ ##
-- ## Edit
-- ## ------------------------------ ##
--
-- yank/paste in system clipboard
-- map('n', 'yp', ':let @+ = expand("%:p:h:.")<CR>', { desc = "Copy current file path to system clipboard" })
map('n', '<C-A>', 'gg"+yG', { desc = "Copy all the contents in system clipboard" })
map('n', 'sy', '"+y', { desc = "Copy to system clipboard" })
map('n', 'sp', '"+p', { desc = "Paste from system clipboard" })
map('x', 'sy', '"+y', { desc = "Copy to system clipboard" })
map('x', 'sp', '"+p', { desc = "Paste from system clipboard" })
map('n', '<C-a>', 'ggVG', { desc = "Select all the content of current buffer" })
map('x', '<C-c>', '"+y""y', { desc = "Copy to system clipboard and nvim internal clipboard" })
map('i', '<C-v>', '"+p', { desc = "Paste from system clipboard" })
vim.keymap.set('n', 'yp', copy_path_to_clip, { desc = "Copy Relative Directory Path to Clipboard" })

--
-- insert 模式下，跳到行首行尾
map('i', '<C-a>', '<Home>', { desc = "Insert mode, move to line header" })
map('i', '<C-e>', '<End>', { desc = "Insert mode, move to line end" })
map('i', '<C-d>', '<Delete>', { desc = "" })
map('i', '<C-h>', '<BS>', { desc = "" })
map('i', '<C-f>', '<Right>', { desc = "" })
map('i', '<C-b>', '<Left>', { desc = "" })
map('i', '<A-f>', '<S-Right>', { desc = "" })
map('i', '<A-b>', '<S-Left>', { desc = "" })
--
-- mark and Highlight word
map('n', '<leader>m', '<leader>s8<leader>k', { desc = "Mark word.", remap = true })
map('x', '<leader>m', '<leader>s8gv<leader>k', { desc = "Mark word.", remap = true })
map('n', '<leader>M', '<leader>s9<leader>K', { desc = "", remap = true })
map('n', '<C-n>', ':Noice dismiss<CR> :silent noh<CR>', { desc = "Dismiss Highlight word and Noice message" })
--
-- Markdown
map('i', '<A-`>', "``````<left><left><left>", { desc = "Markdown: Insert Code Block" })
map('i', '<A-">', "\"\"\"\"\"\"<left><left><left>", { desc = "Markdown: Multiple comment" })

-- Virtual mode text wrapping
map('v', '<A-`>', 'c`<C-r>"`<Esc>', { desc = "Wrap `selection` with backticks" })
map('v', '<A-[>', 'c[<C-r>"]<Esc>', { desc = "Wrap selection with square brackets" })
map('v', '<A-{>', 'c{<C-r>"}<Esc>', { desc = "Wrap selection with curly braces" })
map('v', '<A-">', 'c"<C-r>""<Esc>', { desc = "Wrap selection with double quotes" })
map('v', '<A-\'>', "c'<C-r>\"'<Esc>", { desc = "Wrap selection with single quotes" })
map('v', '<A-<>', 'c<<C-r>"><Esc>', { desc = "Wrap selection with angle brackets" })
map('v', '<A-(>', 'c(<C-r>")<Esc>', { desc = "Wrap selection with parentheses" })

-- ## ------------------------------ ##
-- ## Coding
-- ## ------------------------------ ##
--
-- gtags
map({ "n", "v" }, "<leader>ss", "<cmd>Cs find s<cr>", { desc = "Find all references to the token under cursor" })
map({ "n", "v" }, "<leader>sg", "<cmd>Cs find g<cr>", { desc = "Find global definition(s) of the token under cursor" })
map({ "n", "v" }, "<leader>sc", "<cmd>Cs find c<cr>", { desc = "Find all calls to the function name under cursor" })
map({ "n", "v" }, "<leader>st", "<cmd>Cs find t<cr>", { desc = "Find all instances of the text under cursor" })
map({ "n", "v" }, "<leader>se", "<cmd>Cs find e<cr>", { desc = "Egrep search for the word under cursor" })
map({ "n", "v" }, "<leader>sf", "<cmd>Cs find f<cr>", { desc = "Open the filename under cursor" })
map({ "n", "v" }, "<leader>si", "<cmd>Cs find i<cr>", { desc = "Find files that include the filename under cursor" })
map({ "n", "v" }, "<leader>sd", "<cmd>Cs find d<cr>", { desc = "Find functions that function under cursor calls" })
map({ "n", "v" }, "<leader>sa", "<cmd>Cs find a<cr>", { desc = "Find places where this symbol is assigned a value" })
--
-- Diagnos Trouble
map("n", "<leader>de", ":lua toggle_diagnostics()<CR>", { desc = "Diag: Toggle diagnostics in file" })
map("n", "<leader>dx", ":Trouble diagnostics toggle filter.buf=0<CR>", { desc = "Diag: Toggle diagnostics on current buffer" })  -- Buffer Diagnostics (Trouble)
map("n", "<leader>dX", ":Trouble diagnostics toggle<CR>", { desc = "Diag: toggle diagnostics on project" })               -- Diagnostics (Trouble)
map("n", "<leader>ds", ":Trouble symbols toggle focus=false<CR>", { desc = "Diag: Open LSP symbols" })       -- Symbols (Trouble)
map("n", "<leader>dl", ":Trouble lsp toggle focus=false win.position=right<CR>", { desc = "Diag: Open LSP def/ref/..." })  -- LSP Definitions / references / ... (Trouble)
map("n", "<leader>dL", ":Trouble loclist toggle<CR>", { desc = "Diag: Open Trouble local list" })                   -- Location List (Trouble)
map("n", "<leader>dq", ":Trouble qflist toggle<CR>", { desc = "Diag: Open Trouble Quickfix" })                    -- Quickfix List (Trouble)
map("n", "<leader>dt", ":TagbarToggle<CR>", { desc = "Diag: Open Tagbar" })                    -- Quickfix List (Trouble)
--
-- git
map('n', '<leader>gb', ':BlameToggle<CR>', { desc = "Git: Diplay Blame history" })
map('n', '<leader>gn', ':GetGithubFileUrl<CR>', { desc = "Git: Diplay current file URL" })
--
-- format - conform
map("n", "<leader>=", ':lua require("conform").format({aysnc = true})<CR>', { desc = "Format code for whole file" })
map('x', '<leader>=', ':<C-U>Format<CR>', { desc = "Format code for block" })
map('v', '<leader>=j', ':!jq .<CR>', { desc = "Format json code for block" })
--
return pluginKeys
