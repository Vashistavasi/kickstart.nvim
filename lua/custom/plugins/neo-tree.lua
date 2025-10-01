  return {
    
    {
    'nvim-neo-tree/neo-tree.nvim',
    branch = 'v3.x',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-tree/nvim-web-devicons', -- needed for filetype glyphs
      'MunifTanjim/nui.nvim',
      'mrbjarksen/neo-tree-diagnostics.nvim',
    },
    config = function()
      local neotree = require 'neo-tree.command'
      local ok_diagnostics, neo_tree_diagnostics = pcall(require, 'neo-tree-diagnostics')
      if ok_diagnostics then
        neo_tree_diagnostics.setup {}
      end

      local sources = {
        'filesystem',
        'buffers',
        'git_status',
      }

      local selector_sources = {
        { source = 'filesystem', display_name = '  Files ' },
        { source = 'buffers', display_name = '  Buffers ' },
        { source = 'git_status', display_name = '  Git ' },
      }

      if ok_diagnostics then
        table.insert(sources, 'diagnostics')
        table.insert(selector_sources, { source = 'diagnostics', display_name = '  Diagnostics ' })
      end

      local config = {
        sources = sources,
        source_selector = {
          winbar = true,
          content_layout = 'center',
          truncation_character = '>',
          sources = selector_sources,
        },
        default_component_configs = {
          icon = {
            folder_closed = '',
            folder_open = '',
            folder_empty = '',
            folder_empty_open = '',
            default = '',
          },
          git_status = {
            symbols = {
              added = '',
              deleted = '',
              modified = '',
              renamed = '󰁕',
              untracked = '?',
              ignored = '',
              unstaged = '',
              staged = '',
              conflict = '',
            },
          },
          diagnostics = {
            symbols = {
              hint = '󰌶',
              info = '',
              warn = '',
              error = '',
            },
          },
        },
        filesystem = {
          bind_to_cwd = true,
          follow_current_file = { enabled = true }, -- auto-reveal active buffer
          hijack_netrw_behavior = 'open_default', -- replace :Ex with Neo-tree
          use_libuv_file_watcher = true,
          filtered_items = {
            hide_dotfiles = false,
            hide_gitignored = false,
            hide_by_name = { '.DS_Store' },
          },
        },
        buffers = {
          follow_current_file = { enabled = true },
        },
        git_status = {
          window = { position = 'float' },
        },
        window = {
          position = 'left',
          width = 36,
          mappings = {
            ['s'] = 'open_split', -- horizontal split in same window
            ['v'] = 'open_vsplit', -- vertical split
            ['h'] = 'close_node', -- optional: collapse like netrw
            ['l'] = 'open', -- optional: expand/open
            ['/'] = 'fuzzy_finder', -- pop up fuzzy finder inside neo-tree
            ['#'] = 'fuzzy_finder_directory', -- scoped fuzzy find
            ['<space>'] = 'toggle_preview', -- preview file without leaving tree
            ['P'] = { 'toggle_preview', config = { use_float = true } }, -- float preview
          },
        },
      }

      if ok_diagnostics then
        config.diagnostics = { bind_to_cwd = false }
      end

      require('neo-tree').setup(config)
      --      vim.keymap.set('n', '<leader>e', ':Neotree toggle<CR>', { desc = 'Toggle file tree' })
      vim.keymap.set('n', '<leader>e', function()
        neotree.execute { toggle = true, position = 'left', reveal = true }
      end, { desc = 'Toggle Neo-tree (focus tree when open)' })
    end,
  }
}