-- LazyVim custom options
vim.g.mapleader = " "
vim.g.maplocalleader = ","

-- Editor basics
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.linebreak = true
vim.opt.showmode = false
vim.opt.cursorline = true
vim.opt.scrolloff = 10
vim.opt.sidescrolloff = 8
vim.opt.mouse = "a"
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.timeoutlen = 400
vim.opt.updatetime = 250
vim.opt.undofile = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.signcolumn = "yes"
vim.opt.confirm = true
vim.opt.wrap = false
vim.opt.hlsearch = true
vim.opt.incsearch = true
vim.opt.grepformat = "%f:%l:%c:%m"
vim.opt.grepprg = "rg --vimgrep"
vim.opt.inccommand = "split"

-- Indentation
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.smartindent = true

-- Performance
vim.loader.enable()

-- Diagnostics
vim.diagnostic.config({
  virtual_text = true,
  signs = true,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
  float = {
    border = "rounded",
    source = true,
    header = "",
    prefix = "",
  },
})

-- Statusline
vim.opt.laststatus = 3
vim.opt.winminwidth = 10

-- File encoding
vim.opt.encoding = "UTF-8"

-- Line guide
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "python", "javascript", "typescript", "rust", "go" },
  callback = function() vim.opt_local.colorcolumn = "100" end,
})
