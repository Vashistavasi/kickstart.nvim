return {
  {
    'mfussenegger/nvim-jdtls',
    ft = { 'java' },
    dependencies = {
      'williamboman/mason.nvim',
      'mfussenegger/nvim-dap',
      'rcarriga/nvim-dap-ui',
      'jay-babu/mason-nvim-dap.nvim',
    },
    config = function()
      local root_markers = { 'mvnw', 'gradlew', 'pom.xml', 'build.gradle', '.git' }
      local workspace_base = vim.fn.stdpath 'data' .. '/jdtls/workspace'
      vim.fn.mkdir(workspace_base, 'p')
      local mason_path = vim.fn.stdpath 'data' .. '/mason'
      local jdtls_cmd = mason_path .. '/bin/jdtls'

      local function collect_bundles()
        local packages_path = mason_path .. '/packages'
        local function glob(pattern)
          return vim.fn.glob(pattern, true, true)
        end

        local bundles = {}
        vim.list_extend(bundles, glob(packages_path .. '/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar'))
        vim.list_extend(bundles, glob(packages_path .. '/java-test/extension/server/*.jar'))

        return bundles
      end

      local function start_jdtls()
        local ok, jdtls = pcall(require, 'jdtls')
        if not ok then
          return
        end

        local setup = require 'jdtls.setup'
        local ok_dap, jdtls_dap = pcall(require, 'jdtls.dap')

        local root_dir = setup.find_root(root_markers)
        local buffer_dir = vim.fn.expand '%:p:h'
        local bufname = vim.api.nvim_buf_get_name(0)
        local standalone = not root_dir or root_dir == ''

        if standalone then
          root_dir = buffer_dir
        end

        local project_name
        if standalone then
          if bufname == '' then
            bufname = buffer_dir .. '/Standalone'
          end
          project_name = 'standalone-' .. vim.fn.fnamemodify(bufname, ':t:r')
        else
          project_name = vim.fs.basename(root_dir)
        end

        local workspace_dir = workspace_base .. '/' .. project_name
        vim.fn.mkdir(workspace_dir, 'p')

        local config = {
          cmd = { jdtls_cmd, '-data', workspace_dir },
          root_dir = root_dir,
          init_options = { bundles = collect_bundles() },
          settings = {
            java = {
              configuration = { updateBuildConfiguration = 'automatic' },
            },
          },
          on_attach = function(client, bufnr)
            jdtls.setup_dap { hotcodereplace = 'auto' }
            if ok_dap then
              jdtls_dap.setup_dap_main_class_configs()
            end
          end,
        }

        if standalone then
          config.settings.java.project = {
            referencedLibraries = { bufname ~= '' and bufname or (buffer_dir .. '/Standalone.java') },
          }
        end

        jdtls.start_or_attach(config)
      end

      vim.api.nvim_create_autocmd('FileType', {
        pattern = 'java',
        callback = start_jdtls,
        group = vim.api.nvim_create_augroup('CustomJdtls', { clear = true }),
      })
    end,
  },
}
