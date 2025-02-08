--local colorscheme = "desertmss"
--local colorscheme = "tokyonight-storm"
local colorscheme = "catppuccin-frappe"
local status_ok, _ = pcall(vim.cmd, "colorscheme " .. colorscheme)
if not status_ok then
  vim.notify("colorscheme " .. colorscheme .. " 没有找到！")
  return
end

