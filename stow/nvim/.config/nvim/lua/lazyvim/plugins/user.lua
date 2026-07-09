return {
  -- Flash.nvim (better motion than flash.nvim/which-key)
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {
      labels = "hkdl",
      search = {
        mode = "normal",
      },
    },
    keys = {
      { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash Jump" },
      { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
      { "r", mode = "o", function() require("flash").remote() end, desc = "Remote Flash" },
    },
  },

  -- Trouble.nvim (better diagnostics)
  {
    "folke/trouble.nvim",
    cmd = "Trouble",
    keys = {
      { "<leader>xx", "<cmd>Trouble diagnostics toggle<CR>", desc = "Diagnostics (Trouble)" },
      { "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<CR>", desc = "Buffer Diagnostics" },
      { "<leader>xs", "<cmd>Trouble symbols toggle<CR>", desc = "Symbols" },
      { "<leader>xL", "<cmd>Trouble loclist toggle<CR>", desc = "Location List" },
      { "<leader>xQ", "<cmd>Trouble qflist toggle<CR>", desc = "Quickfix List" },
    },
  },

  -- Todo comments
  {
    "folke/todo-comments.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {
      signs = false,
      keywords = {
        FIX = { icon = " ", color = "diagnostic.error" },
        TODO = { icon = " ", color = "diagnostic.info" },
        HACK = { icon = " ", color = "diagnostic.warn" },
        WARN = { icon = " ", color = "diagnostic.warn" },
        NOTE = { icon = " ", color = "diagnostic.hint" },
        PERF = { icon = " ", color = "diagnostic.hint" },
      },
    },
  },

  -- Dressing.nvim (better input)
  {
    "stevearc/dressing.nvim",
    event = "VeryLazy",
    opts = {},
  },

  -- Quick scope highlighting
  {
    "unobtanium/quick-scope.nvim",
    event = "VeryLazy",
    config = function()
      require("quick_scope").setup({
        highlight = { other = "Comment",善 = "Conceal" },
      })
    end,
  },

  -- Autopairs
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = true,
    dependencies = { "hrsh7th/nvim-cmp" },
  },
}
