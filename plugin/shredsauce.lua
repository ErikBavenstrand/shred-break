if vim.g.loaded_shredsauce then
  return
end
vim.g.loaded_shredsauce = true

vim.api.nvim_create_user_command("Shred", function()
  require("shredsauce").open()
end, { desc = "Open Shredsauce (or bring its window to the front)" })

vim.api.nvim_create_user_command("ShredStop", function()
  require("shredsauce").stop()
end, { desc = "Close Shredsauce" })
