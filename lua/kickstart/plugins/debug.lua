-- debug.lua
--
-- Shows how to use the DAP plugin to debug your code.
--
-- Primarily focused on configuring the debugger for Go, but can
-- be extended to other languages as well. That's why it's called
-- kickstart.nvim and not kitchen-sink.nvim ;)

return {
  -- NOTE: Yes, you can install new plugins here!
  'mfussenegger/nvim-dap',
  -- NOTE: And you can specify dependencies as well
  dependencies = {
    -- Creates a beautiful debugger UI
    'rcarriga/nvim-dap-ui',

    -- Required dependency for nvim-dap-ui
    'nvim-neotest/nvim-nio',

    -- Installs the debug adapters for you
    'mason-org/mason.nvim',
    'jay-babu/mason-nvim-dap.nvim',

    -- Add your own debuggers here
    'leoluz/nvim-dap-go',

    -- JavaScript / TypeScript debugging
    'mxsdev/nvim-dap-vscode-js',

    -- Java LSP and DAP integration
    'mfussenegger/nvim-jdtls',
  },
  keys = {
    -- Basic debugging keymaps, feel free to change to your liking!
    {
      '<F5>',
      function()
        require('dap').continue()
      end,
      desc = 'Debug: Start/Continue',
    },
    {
      '<F1>',
      function()
        require('dap').step_into()
      end,
      desc = 'Debug: Step Into',
    },
    {
      '<F2>',
      function()
        require('dap').step_over()
      end,
      desc = 'Debug: Step Over',
    },
    {
      '<F3>',
      function()
        require('dap').step_out()
      end,
      desc = 'Debug: Step Out',
    },
    {
      '<leader>b',
      function()
        require('dap').toggle_breakpoint()
      end,
      desc = 'Debug: Toggle Breakpoint',
    },
    {
      '<leader>B',
      function()
        require('dap').set_breakpoint(vim.fn.input 'Breakpoint condition: ')
      end,
      desc = 'Debug: Set Breakpoint',
    },
    -- Toggle to see last session result. Without this, you can't see session output in case of unhandled exception.
    {
      '<F7>',
      function()
        require('dapui').toggle()
      end,
      desc = 'Debug: See last session result.',
    },
  },
  config = function()
    local dap = require 'dap'
    local dapui = require 'dapui'
    local mason_path = vim.fn.stdpath 'data' .. '/mason'

    require('mason-nvim-dap').setup {
      -- Makes a best effort to setup the various debuggers with
      -- reasonable debug configurations
      automatic_installation = true,

      -- You can provide additional configuration to the handlers,
      -- see mason-nvim-dap README for more information
      handlers = {},

      -- You'll need to check that you have the required things installed
      -- online, please don't ask me how to install them :)
      ensure_installed = {
        -- Update this to ensure that you have the debuggers for the langs you want
        'delve',
        'java-debug-adapter',
        'java-test',
        'bash',
        'js',
      },
    }

    -- Dap UI setup
    -- For more information, see |:help nvim-dap-ui|
    dapui.setup {
      -- Set icons to characters that are more likely to work in every terminal.
      --    Feel free to remove or use ones that you like more! :)
      --    Don't feel like these are good choices.
      icons = { expanded = '▾', collapsed = '▸', current_frame = '*' },
      controls = {
        icons = {
          pause = '⏸',
          play = '▶',
          step_into = '⏎',
          step_over = '⏭',
          step_out = '⏮',
          step_back = 'b',
          run_last = '▶▶',
          terminate = '⏹',
          disconnect = '⏏',
        },
      },
    }

    -- Change breakpoint icons
    vim.api.nvim_set_hl(0, 'DapBreak', { fg = '#e51400' })
    vim.api.nvim_set_hl(0, 'DapStop', { fg = '#ffcc00' })
    local breakpoint_icons = vim.g.have_nerd_font
        and { Breakpoint = '', BreakpointCondition = '', BreakpointRejected = '', LogPoint = '', Stopped = '' }
      or { Breakpoint = '●', BreakpointCondition = '⊜', BreakpointRejected = '⊘', LogPoint = '◆', Stopped = '⭔' }
    for type, icon in pairs(breakpoint_icons) do
      local tp = 'Dap' .. type
      local hl = (type == 'Stopped') and 'DapStop' or 'DapBreak'
      vim.fn.sign_define(tp, { text = icon, texthl = hl, numhl = hl })
    end

    dap.listeners.after.event_initialized['dapui_config'] = dapui.open
    dap.listeners.before.event_terminated['dapui_config'] = dapui.close
    dap.listeners.before.event_exited['dapui_config'] = dapui.close

    -- Install golang specific config
    require('dap-go').setup {
      delve = {
        -- On Windows delve must be run attached or it crashes.
        -- See https://github.com/leoluz/nvim-dap-go/blob/main/README.md#configuring
        detached = vim.fn.has 'win32' == 0,
      },
    }

    ---------------------------------------------------------------------------
    -- 🐚 Bash DAP Setup
    ---------------------------------------------------------------------------
    local function setup_bash_debug()
      local bash_adapter = vim.fn.exepath 'bash-debug-adapter'
      if bash_adapter == '' then
        local mason_bin = mason_path .. '/bin/bash-debug-adapter'
        if vim.fn.filereadable(mason_bin) == 1 then
          bash_adapter = mason_bin
        end
      end

      if bash_adapter == '' then
        vim.notify('bash-debug-adapter not found in PATH or Mason bin', vim.log.levels.WARN)
        return
      end

      dap.adapters.bash = {
        type = 'executable',
        command = bash_adapter,
        name = 'bashdb',
      }

      local bash_package_root = mason_path .. '/packages/bash-debug-adapter/extension/bashdb_dir'
      local bashdb_script = bash_package_root .. '/bashdb'

      if vim.fn.filereadable(bashdb_script) == 0 then
        vim.notify('bash-debug-adapter missing bashdb script at ' .. bashdb_script, vim.log.levels.WARN)
        return
      end
      local function exe_or(cmd, fallback)
        local path = vim.fn.exepath(cmd)
        return (path ~= '' and path) or fallback or cmd
      end

      local bash_config = {
        type = 'bash',
        request = 'launch',
        name = 'Bash: Launch file',
        program = '${file}',
        cwd = '${fileDirname}',
        pathBashdb = bashdb_script,
        pathBashdbLib = bash_package_root,
        pathBash = exe_or('bash'),
        pathCat = exe_or('cat'),
        pathMkfifo = exe_or('mkfifo'),
        pathPkill = exe_or('pkill'),
        env = {},
        args = {},
        terminalKind = 'integrated',
      }

      dap.configurations.sh = { vim.deepcopy(bash_config) }
      dap.configurations.bash = { bash_config }
    end

    setup_bash_debug()

    ---------------------------------------------------------------------------
    -- ⚙️  JavaScript / TypeScript DAP Setup
    ---------------------------------------------------------------------------
    local function setup_typescript_debug()
      local ok_vscode, vscode_js = pcall(require, 'dap-vscode-js')
      if not ok_vscode then
        vim.notify('dap-vscode-js not found, skipping JS/TS debug setup', vim.log.levels.WARN)
        return
      end

      local debugger_path = mason_path .. '/packages/js-debug-adapter'
      if vim.fn.isdirectory(debugger_path) == 0 then
        vim.notify('js-debug-adapter is not installed. Install it with :MasonInstall js-debug-adapter', vim.log.levels.WARN)
        return
      end

      vscode_js.setup {
        debugger_path = debugger_path,
        adapters = { 'pwa-node', 'pwa-chrome', 'pwa-msedge', 'node-terminal', 'pwa-extensionHost' },
      }

      local dap_utils = require 'dap.utils'
      local skip_files = { '<node_internals>/**', '${workspaceFolder}/node_modules/**' }
      local function with_configs(filetypes, configs)
        for _, ft in ipairs(filetypes) do
          dap.configurations[ft] = dap.configurations[ft] or {}
          for _, cfg in ipairs(configs) do
            table.insert(dap.configurations[ft], vim.deepcopy(cfg))
          end
        end
      end

      local ts_launch = {
        type = 'pwa-node',
        request = 'launch',
        name = 'TS Debug: Current File (ts-node)',
        program = '${file}',
        cwd = '${workspaceFolder}',
        runtimeExecutable = 'node',
        runtimeArgs = { '-r', 'ts-node/register', '-r', 'tsconfig-paths/register' },
        sourceMaps = true,
        resolveSourceMapLocations = { '${workspaceFolder}/**', '!**/node_modules/**' },
        skipFiles = skip_files,
        console = 'integratedTerminal',
      }

      local ts_compiled = {
        type = 'pwa-node',
        request = 'launch',
        name = 'TS Debug: Launch Compiled Output',
        program = '${workspaceFolder}/dist/${relativeFileDirname}/${fileBasenameNoExtension}.js',
        cwd = '${workspaceFolder}',
        sourceMaps = true,
        outFiles = { '${workspaceFolder}/dist/**/*.js', '${workspaceFolder}/build/**/*.js' },
        resolveSourceMapLocations = { '${workspaceFolder}/**', '!**/node_modules/**' },
        skipFiles = skip_files,
        console = 'integratedTerminal',
      }

      local ts_attach = {
        type = 'pwa-node',
        request = 'attach',
        name = 'TS Debug: Attach to Process',
        processId = dap_utils.pick_process,
        cwd = '${workspaceFolder}',
        skipFiles = skip_files,
      }

      with_configs({ 'typescript', 'typescriptreact', 'javascript', 'javascriptreact' }, {
        ts_launch,
        ts_compiled,
        ts_attach,
      })
    end

    setup_typescript_debug()

    ---------------------------------------------------------------------------
    -- 🧩 Java DAP + JDTLS Setup
    ---------------------------------------------------------------------------
    -- Install Java debug adapters automatically
    ---------------------------------------------------------------------------
    -- Java Debugging (Unified Project + Standalone Mode)
    ---------------------------------------------------------------------------
    local function setup_java_debug()
      local ok, jdtls = pcall(require, 'jdtls')
      if not ok then
        vim.notify('nvim-jdtls not found, skipping Java setup', vim.log.levels.WARN)
        return
      end

      local root_markers = { 'pom.xml', 'build.gradle', '.git' }
      local root_dir = require('jdtls.setup').find_root(root_markers)
      local standalone = (not root_dir or root_dir == '')

      local java_debug_jar = vim.fn.glob(mason_path .. '/packages/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar', 1)
      local java_test_jars = vim.split(vim.fn.glob(mason_path .. '/packages/java-test/extension/server/*.jar', 1), '\n')
      local bundles = { java_debug_jar }
      vim.list_extend(bundles, java_test_jars)

      if standalone then
        -------------------------------------------------------------------
        -- ⚡ Standalone Java (no project)
        -------------------------------------------------------------------
        vim.notify('☕ Standalone Java mode (no Maven/Gradle)', vim.log.levels.INFO)

        dap.adapters.java = { type = 'executable', command = mason_path .. '/bin/jdtls' }
        dap.configurations.java = {
          {
            type = 'java',
            request = 'launch',
            name = 'Run current Java file',
            mainClass = function()
              return vim.fn.expand '%:t:r'
            end,
            projectName = 'standalone',
            cwd = vim.fn.expand '%:p:h',
            console = 'integratedTerminal',
          },
        }

        vim.keymap.set('n', '<leader>jc', function()
          require('dap').continue()
        end, { desc = 'Run Java file (standalone)' })
      else
        -------------------------------------------------------------------
        -- 🧩 Project Mode (JDTLS LSP + DAP)
        -------------------------------------------------------------------
        vim.notify('☕ JDTLS Project mode enabled for: ' .. root_dir, vim.log.levels.INFO)
        local workspace = vim.fn.expand '~/.cache/jdtls/workspace/' .. vim.fn.fnamemodify(root_dir, ':p:h:t')
        local config = {
          cmd = { mason_path .. '/bin/jdtls', '-data', workspace },
          root_dir = root_dir,
          init_options = { bundles = bundles },
          settings = {
            java = {
              autobuild = { enabled = false },
              project = { resourceFilters = { 'node_modules', '.git' } },
              import = { gradle = { enabled = true }, maven = { enabled = true } },
            },
          },
        }
        jdtls.start_or_attach(config)

        -- JUnit test keymaps
        vim.keymap.set('n', '<leader>dj', function()
          require('jdtls').test_class()
        end, { desc = 'Debug Java Test Class' })
        vim.keymap.set('n', '<leader>dn', function()
          require('jdtls').test_nearest_method()
        end, { desc = 'Debug Nearest Java Test' })
      end
    end

    vim.api.nvim_create_autocmd('FileType', {
      pattern = 'java',
      callback = setup_java_debug,
    })
  end,
}
