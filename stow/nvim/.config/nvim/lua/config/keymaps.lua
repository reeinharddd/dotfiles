-- LazyVim custom keymaps
local map = vim.keymap.set

-- Better escape
map("i", "jk", "<Esc>", { desc = "Exit insert mode" })

-- Center on scroll
map("n", "<C-d>", "<C-d>zz", { desc = "Scroll down and center" })
map("n", "<C-u>", "<C-u>zz", { desc = "Scroll up and center" })
map("n", "n", "nzzzv", { desc = "Next match and center" })
map("n", "N", "Nzzzv", { desc = "Previous match and center" })

-- Window navigation
map("n", "<C-h>", "<C-w>h", { desc = "Window left" })
map("n", "<C-l>", "<C-w>l", { desc = "Window right" })
map("n", "<C-j>", "<C-w>j", { desc = "Window down" })
map("n", "<C-k>", "<C-w>k", { desc = "Window up" })

-- Move lines
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move block down" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move block up" })

-- Center on jump
map("n", "<C-o>", "<C-o>zz", { desc = "Jump back and center" })

-- Diagnostics
map("n", "<leader>e", vim.diagnostic.open_float, { desc = "Diagnostic float" })
map("n", "[d", function() vim.diagnostic.jump({ count = -1, float = true }) end, { desc = "Prev diagnostic" })
map("n", "]d", function() vim.diagnostic.jump({ count = 1, float = true }) end, { desc = "Next diagnostic" })

-- LSP
map("n", "<leader>rn", vim.lsp.buf.rename, { desc = "Rename symbol" })
map("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "Code action" })
map({ "n", "v" }, "<leader>cf", function() vim.lsp.buf.format({ async = true }) end, { desc = "Format buffer" })

-- OpenCode TUI in split
map("n", "<leader>ai", function()
  vim.cmd("split | terminal opencode")
  vim.cmd("resize 20")
end, { desc = "Open Opencode TUI (split)" })

map("n", "<leader>aA", function()
  vim.cmd("vnew | terminal opencode")
  vim.cmd("vertical resize 80")
end, { desc = "Open Opencode in vertical split" })

-- Terminal mode
map("t", "jk", "<C-\\><C-n>", { desc = "Exit terminal mode" })
map("t", "<Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- Save
map({ "n", "i", "v" }, "<C-s>", "<cmd>w<CR>", { desc = "Save file" })

-- Clipboard
map("v", "<leader>y", '"+y', { desc = "Yank to clipboard" })
map("n", "<leader>y", '"+y', { desc = "Yank to clipboard" })
map("n", "<leader>Y", '"+y$', { desc = "Yank line to clipboard" })
