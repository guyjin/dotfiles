return {
    {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-tree/nvim-web-devicons", -- optional, but recommended
      "folke/snacks.nvim",
    },
    lazy = false,
    opts = {
      filesystem = {
        filtered_items = {
          visible = true,
          show_hidden_count = true,
          hide_dotfiles = false,
          hide_gitignored = true,
          -- hide_by_name = {
          --  ".git",
          --  ".DS_Store",
          --  "thumbs.db"
          --},
          never_show = { ".DS_Store", ".git", "thumbs.db"},
        },
      },
    },
      config = function(_, opts)
        require("neo-tree").setup(opts)
        vim.keymap.set('n', '<C-n>', ':Neotree filesystem reveal right<CR>', {})
      end,
  },
  {
    "antosha417/nvim-lsp-file-operations",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-neo-tree/neo-tree.nvim", -- makes sure that this loads after Neo-tree.
    },
    config = function()
      require("lsp-file-operations").setup()
    end,
  },
}
