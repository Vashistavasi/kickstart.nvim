-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information
return {
  -- {
  --   'mfussenegger/nvim-jdtls',
  --   -- event="VimEnter",
  --   -- ft = 'java',  -- Only load for Java files
  --   -- dependencies = {
  --   --   'williamboman/mason.nvim',
  --   --   'williamboman/mason-lspconfig.nvim',
  --   -- }
  -- },
  -- {
  --   'echasnovski/mini.files',
  --   version = false, -- let Lazy use the rolling release bundled in mini.nvim
  --   config = function()
  --     require('mini.files').setup() -- accept defaults; adds the explorer
  --     vim.keymap.set('n', '<leader>fe', MiniFiles.open, { desc = 'File explorer (cwd)' })
  --     vim.keymap.set('n', '<leader>fE', function()
  --       MiniFiles.open(vim.api.nvim_buf_get_name(0)) -- start at current file
  --     end, { desc = 'File explorer (file dir)' })
  --   end,
  -- },


}
