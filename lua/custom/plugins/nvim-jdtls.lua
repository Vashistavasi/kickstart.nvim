return {
  {
    'mfussenegger/nvim-jdtls',
    ft = { 'java' },
    dependencies = {
      'mason-org/mason.nvim',
      'mfussenegger/nvim-dap',
    },
    config = function()
      local root_markers = { 'mvnw', 'gradlew', 'pom.xml', 'build.gradle', 'build.gradle.kts', 'settings.gradle', 'settings.gradle.kts', '.git' }
      local workspace_base = vim.fs.joinpath(vim.fn.stdpath 'data', 'jdtls', 'workspace')
      vim.fn.mkdir(workspace_base, 'p')
      local mason_path = vim.fs.joinpath(vim.fn.stdpath 'data', 'mason')
      local jdtls_cmd = vim.fs.joinpath(mason_path, 'bin', 'jdtls')

      local function buffer_name(bufnr)
        return vim.api.nvim_buf_get_name(bufnr)
      end

      local function glob(pattern)
        return vim.fn.glob(pattern, true, true)
      end

      local function collect_bundles()
        local packages_path = vim.fs.joinpath(mason_path, 'packages')
        local bundles = {}
        local seen = {}

        for _, path in ipairs(glob(packages_path .. '/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar')) do
          if path ~= '' and not seen[path] then
            table.insert(bundles, path)
            seen[path] = true
          end
        end

        for _, path in ipairs(glob(packages_path .. '/java-test/extension/server/*.jar')) do
          if path ~= '' and not seen[path] then
            table.insert(bundles, path)
            seen[path] = true
          end
        end

        return bundles
      end

      local function java_capabilities()
        local ok_blink, blink = pcall(require, 'blink.cmp')
        if ok_blink then
          return blink.get_lsp_capabilities()
        end
        return vim.lsp.protocol.make_client_capabilities()
      end

      local function resolve_root(bufnr)
        local bufname = buffer_name(bufnr)
        if bufname == '' then
          return nil, nil
        end

        local setup = require 'jdtls.setup'
        local detected_root = setup.find_root(root_markers, bufname)
        if detected_root and detected_root ~= '' then
          return detected_root, false
        end

        return vim.fs.dirname(bufname), true
      end

      local function workspace_dir(root_dir, standalone)
        local normalized = vim.fs.normalize(root_dir)
        local basename = vim.fs.basename(normalized):gsub('[^%w_.-]', '_')
        local hash = vim.fn.sha256(normalized):sub(1, 8)
        local prefix = standalone and 'standalone-' or ''
        local dir = vim.fs.joinpath(workspace_base, string.format('%s%s-%s', prefix, basename, hash))
        vim.fn.mkdir(dir, 'p')
        return dir
      end

      local function set_java_keymaps(bufnr)
        local map = function(lhs, rhs, desc)
          vim.keymap.set('n', lhs, rhs, { buffer = bufnr, desc = desc })
        end

        map('<leader>jC', function()
          vim.ui.input({ prompt = 'Java class to open: ' }, function(input)
            if not input or input == '' then
              return
            end
            require('jdtls').open_classfile(input)
          end)
        end, 'Java: Open Class')

        map('<leader>jo', function()
          require('jdtls').organize_imports()
        end, 'Java: Organize Imports')

        map('<leader>jc', function()
          local dap = require 'dap'
          local root_dir = select(1, resolve_root(bufnr))

          if not root_dir then
            vim.notify('Could not determine a Java root for this buffer', vim.log.levels.WARN)
            return
          end

          dap.run {
            type = 'java',
            request = 'launch',
            name = 'Java: Debug Current Main Class',
            cwd = root_dir,
            console = 'integratedTerminal',
          }
        end, 'Java: Debug Current Main Class')

        map('<leader>jt', function()
          require('jdtls').test_class()
        end, 'Java: Debug Test Class')

        map('<leader>jn', function()
          require('jdtls').test_nearest_method()
        end, 'Java: Debug Nearest Test')
      end

      local function start_jdtls(bufnr)
        if vim.bo[bufnr].filetype ~= 'java' then
          return
        end
        if vim.b[bufnr].jdtls_started then
          return
        end
        if #vim.lsp.get_clients { bufnr = bufnr, name = 'jdtls' } > 0 then
          return
        end

        local ok, jdtls = pcall(require, 'jdtls')
        if not ok then
          vim.notify('nvim-jdtls is unavailable', vim.log.levels.WARN)
          return
        end

        local bufname = buffer_name(bufnr)
        if bufname == '' then
          vim.notify('Save the Java file before starting JDTLS', vim.log.levels.INFO)
          return
        end

        if vim.fn.executable(jdtls_cmd) == 0 then
          vim.notify('Mason jdtls executable not found: ' .. jdtls_cmd, vim.log.levels.ERROR)
          return
        end

        local ok_dap, jdtls_dap = pcall(require, 'jdtls.dap')
        local root_dir, standalone = resolve_root(bufnr)
        if not root_dir then
          return
        end

        local config = {
          cmd = { jdtls_cmd, '-data', workspace_dir(root_dir, standalone) },
          root_dir = root_dir,
          init_options = { bundles = collect_bundles() },
          capabilities = java_capabilities(),
          settings = {
            java = {
              autobuild = { enabled = false },
              configuration = { updateBuildConfiguration = 'interactive' },
              contentProvider = { preferred = 'fernflower' },
              completion = {
                favoriteStaticMembers = {
                  'org.assertj.core.api.Assertions.*',
                  'org.junit.jupiter.api.Assertions.*',
                  'org.mockito.Mockito.*',
                },
              },
              eclipse = { downloadSources = true },
              implementationsCodeLens = { enabled = true },
              import = { gradle = { enabled = true }, maven = { enabled = true } },
              maven = { downloadSources = true },
              referencesCodeLens = { enabled = true },
              signatureHelp = { enabled = true },
              sources = {
                organizeImports = {
                  starThreshold = 9999,
                  staticStarThreshold = 9999,
                },
              },
            },
          },
          on_attach = function(_, attached_bufnr)
            jdtls.setup_dap { hotcodereplace = 'auto' }
            if ok_dap then
              jdtls_dap.setup_dap_main_class_configs()
            end
            set_java_keymaps(attached_bufnr)
          end,
        }

        if standalone then
          config.settings.java.project = {
            referencedLibraries = {},
          }
        end

        vim.b[bufnr].jdtls_started = true
        local ok_start, err = pcall(function()
          vim.api.nvim_buf_call(bufnr, function()
            jdtls.start_or_attach(config)
          end)
        end)
        if not ok_start then
          vim.b[bufnr].jdtls_started = nil
          error(err)
        end
      end

      vim.api.nvim_create_autocmd('FileType', {
        pattern = 'java',
        group = vim.api.nvim_create_augroup('CustomJdtls', { clear = true }),
        callback = function(args)
          start_jdtls(args.buf)
        end,
      })

      if vim.bo.filetype == 'java' then
        start_jdtls(vim.api.nvim_get_current_buf())
      end
    end,
  },
}
