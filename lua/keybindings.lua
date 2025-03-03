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
-- ## F1 ~~ F12 Hotkeys
-- ## -------------------------------------- ##
map("n", "<F1>", ":Dashboard<CR>", { desc = "Dashboard" })
map("n", "<F2>", ":Telescope projects<CR>", { desc = "Telescope projects" })
map('n', '<F3>', ":1,$s///g", { desc = "Replace all" })
-- map("n", "<F4>", "", { desc = "Telescope projects" })

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
map("n", "<A-h>", ":vertical resize -15<CR>", { desc = "Reduce vertical windown size" })
map("n", "<A-l>", ":vertical resize +15<CR>", { desc = "Enlarge vertical windown size" })
map("n", "<A-k>", ":resize -10<CR>", { desc = "Reduce horizonal windown size" })
map("n", "<A-j>", ":resize +10<CR>", { desc = "Enlarge horizonal windown size" })
-- 等比例 <C-w>=
-- 关当前窗口 <C-w>c
map("v", "<", "<gv", { desc = "Visual indent" })
map("v", ">", ">gv", { desc = "Visual indent" })
map("v", "J", ":move '>+1<CR>gv-gv", { desc = "Move selected text down" })
map("v", "K", ":move '<-2<CR>gv-gv", { desc = "Move selected text up" })
map("n", "<C-e>", ":b# <CR>", { desc = "switch current buffer" })
-- Bufferline
map("n", "<S-h>", ":BufferLineCyclePrev<CR>", { desc = "BufferLineCyclePrev"})
map("n", "<S-l>", ":BufferLineCycleNext<CR>", { desc = "BufferLineCycleNext"})
map("n", "<S-w>", ":bdelete<CR>", { desc = "BufferLineCloseCurrent"})
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
map("n", "<leader>q", ":q<CR>", { desc = "Close the current window" })
map('n', '<A-q>', toggle_quickfix, { desc = "Toggle quickfix window" })

-- ## ------------------------------ ##
-- ## AI
-- ## ------------------------------ ##
-- Avante
-- map({ "n", "v" }, "<leader>aa", ":AvanteAsk <CR>", { desc = "open dir tree" })
map("n", "<leader>as", ":AvanteSwitchProvider<right>", { desc = "Avante: Switch provider" })
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

-- ## ------------------------------ ##
-- ## Search
-- ## ------------------------------ ##
-- Telescope, find files/global grep
map("n", "sc", ":Telescope ", { desc = "Type :Telescope command" })
map("n", "sf", ":Telescope find_files<CR>", { desc = "Search for files in PWD" })
map("n", "sg", ":Telescope live_grep<CR>", { desc = "Searches for the string in your PWD" })
map("n", "sgd", ":Telescope live_grep search_dirs={'", { desc = "Searches for the string in your PWD with dir" })
map("n", "sgg", ":Telescope grep_string<CR>", { desc = "Searches for the string under your cursor in your PWD" })
map("n", "sb", ":Telescope buffers<CR>", { desc = "Lists open buffers" })
map("n", "sm", ":Telescope oldfiles<CR>", { desc = "Lists previously open files" })
map("n", "ss", ":Telescope current_buffer_fuzzy_find<CR>", { desc = "Search string of the current buffer" })
-- map("n", "ssg", ":Telescope current_buffer_fuzzy_find<CR>", { desc = "Search string of the current buffer" })
map("n", "st", ":Telescope treesitter<CR>", { desc = "Lists function names, variables, and other symbols from treesitter queries" })
map("n", "sh", ":Telescope man_pages sections={'ALL'}<CR>", { desc = "Lists manpage entries" })
map("n", "sk", ":Telescope keymaps <CR>", { desc = "Lists manpage entries" })
-- Telescope 列表中 插入模式快捷键
local open_with_trouble = require("trouble.sources.telescope").open
-- Use this to add more results without clearing the trouble list
local add_to_trouble = require("trouble.sources.telescope").add

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
  mapbuf("x", "<leader>r", ":lua vim.lsp.buf.rename()<CR>", { desc = "LSP rename" })
  mapbuf("n", "<leader>ca", ":lua vim.lsp.buf.code_action()<CR>", { desc = "LSP code action" })
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
map('n', 'sy', '"+y', { desc = "Copy to system clipboard" })
map('n', 'sp', '"+p', { desc = "Paste from system clipboard" })
map('x', 'sy', '"+y', { desc = "Copy to system clipboard" })
map('x', 'sp', '"+p', { desc = "Paste from system clipboard" })
map('x', '<C-c>', '"+y', { desc = "Copy to  system clipboard" })
map('i', '<C-v>', '"+p', { desc = "Paste from system clipboard" })
vim.keymap.set('n', 'yp', function()
    local current_file = vim.api.nvim_buf_get_name(0)
    if vim.fn.empty(current_file) == 1 then
        vim.notify("No file in current buffer", vim.log.levels.WARN, { title = "Copy Relative Dir Path" })
        return
    end

    local current_dir = vim.fn.fnamemodify(current_file, ":h")
    local absolute_filepath = vim.fn.fnamemodify(current_file, ":p") -- ":p" gets the absolute path

    vim.cmd('let @+ = expand("' .. absolute_filepath .. '")')
    vim.notify("Absolute file path copied to clipboard:\n" .. absolute_filepath, vim.log.levels.INFO, { title = "Copy Absolute File Path" })
end, { desc = "Copy Relative Directory Path to Clipboard" })
--
-- insert 模式下，跳到行首行尾
map('i', '<C-a>', '<Home>', { desc = "Insert mode, move to line header" })
map('i', '<C-e>', '<End>', { desc = "Insert mode, move to line end" })
map('i', '<C-d>', '<Delete>', { desc = "" })
map('i', '<C-h>', '<BS>', { desc = "" })
map('i', '<C-f>', '<Right>', { desc = "" })
map('i', '<C-b>', '<Left>', { desc = "" })
map('i', '<M-f>', '<S-Right>', { desc = "" })
map('i', '<M-b>', '<S-Left>', { desc = "" })
--
-- mark and Highlight word
map('n', '<leader>m', '<leader>s8<leader>k', { desc = "Mark word.", remap = true })
map('x', '<leader>m', '<leader>s8gv<leader>k', { desc = "Mark word.", remap = true })
map('n', '<leader>M', '<leader>s9<leader>K', { desc = "", remap = true })
map('n', '<C-n>', ':Noice dismiss<CR> :silent noh<CR>', { desc = "Dismiss Highlight word and Noice message" })
--
-- Markdown
map('i', '<A-`>', "``````<left><left><left>", { desc = "Insert Markdown Code Block" })

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
map("n", "<leader>de", ":lua toggle_diagnostics()<CR>", { desc = "Toggle diagnostics in file" })
map("n", "<leader>dx", ":Trouble diagnostics toggle filter.buf=0<CR>", { desc = "Trouble: toggle diagnostics on current buffer" })  -- Buffer Diagnostics (Trouble)
map("n", "<leader>dX", ":Trouble diagnostics toggle<CR>", { desc = "Trouble: toggle diagnostics on project" })               -- Diagnostics (Trouble)
map("n", "<leader>ds", ":Trouble symbols toggle focus=false<CR>", { desc = "Trouble: Open LSP symbols" })       -- Symbols (Trouble)
map("n", "<leader>dl", ":Trouble lsp toggle focus=false win.position=right<CR>", { desc = "Trouble: Open LSP def/ref/..." })  -- LSP Definitions / references / ... (Trouble)
map("n", "<leader>dL", ":Trouble loclist toggle<CR>", { desc = "Trouble: Open Trouble local list" })                   -- Location List (Trouble)
map("n", "<leader>dq", ":Trouble qflist toggle<CR>", { desc = "Trouble: Open Trouble Quickfix" })                    -- Quickfix List (Trouble)
--
-- git
map('n', '<leader>gb', ':BlameToggle<CR>', { desc = "Git: Diplay Blame history" })
--
-- format - conform
map("n", "<leader>=", ':lua require("conform").format({aysnc = true})<CR>', { desc = "Format code" })
map('x', '<leader>=', ':<C-U>Format<CR>', { desc = "Format code" })
--
-- transfer upload toggle
map('n', '<leader>tt', ':TransferToggle<CR>', { desc = "Transfer: upload toggle" })
-- complete nvim-cmp
pluginKeys.cmp = function(cmp, luasnip)
    local feedkey = function(key, mode)
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(key, true, true, true), mode, true)
    end

    local has_words_before = function()
        local line, col = unpack(vim.api.nvim_win_get_cursor(0))
        return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
    end

    return {
        -- 出现补全
        ["<A-.>"] = cmp.mapping(cmp.mapping.complete(), {"i", "c"}),
        -- 取消
        ["<A-,>"] = cmp.mapping({
            i = cmp.mapping.abort(),
            c = cmp.mapping.close()
        }),
        ["<C-p>"] = cmp.mapping.select_prev_item(),
        ["<C-n>"] = cmp.mapping.select_next_item(),
        -- ["<CR>"] = cmp.mapping.confirm({
        --     select = true,
        --     behavior = cmp.ConfirmBehavior.Replace
        -- }),
        ["<C-u>"] = cmp.mapping(cmp.mapping.scroll_docs(-4), {"i", "c"}),
        ["<C-d>"] = cmp.mapping(cmp.mapping.scroll_docs(4), {"i", "c"}),

        -- LuaSnip Super Tab
        ['<CR>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
                if luasnip.expandable() then
                    luasnip.expand()
                else
                    cmp.confirm({
                        select = true,
                    })
                end
            else
                fallback()
            end
        end),

        ["<Tab>"] = cmp.mapping(function(fallback)
            if luasnip.locally_jumpable(1) then
                luasnip.jump(1)
            elseif cmp.visible() then
                cmp.select_next_item()
            else
                fallback()
            end
        end, { "i", "s" }),

        ["<S-Tab>"] = cmp.mapping(function(fallback)
            if luasnip.locally_jumpable(-1) then
                luasnip.jump(-1)
            elseif cmp.visible() then
                cmp.select_prev_item()
            else
                fallback()
            end
        end, { "i", "s" }),


        -- Vsnip Super Tab
        -- ["<Tab>"] = cmp.mapping(function(fallback)
        --   if cmp.visible() then
        --     cmp.select_next_item()
        --   elseif vim.fn["vsnip#available"](1) == 1 then
        --     feedkey("<Plug>(vsnip-expand-or-jump)", "")
        --   elseif has_words_before() then
        --     cmp.complete()
        --   else
        --     fallback() -- The fallback function sends a already mapped key. In this case, it's probably `<Tab>`.
        --   end
        -- end, {"i", "s"}),
        -- ["<S-Tab>"] = cmp.mapping(function()
        --   if cmp.visible() then
        --     cmp.select_prev_item()
        --   elseif vim.fn["vsnip#jumpable"](-1) == 1 then
        --     feedkey("<Plug>(vsnip-jump-prev)", "")
        --   end
        -- end, {"i", "s"})
    }
end

return pluginKeys
