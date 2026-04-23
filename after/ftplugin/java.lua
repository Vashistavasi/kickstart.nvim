-- ftplugin/java.lua

-- Updated Java ftplugin configuring nvim-jdtls with mason-managed jdtls.
-- Handles root/workspace detection and constructs launch cmd robustly.

local ok, jdtls = pcall(require, 'jdtls')

if not ok then 
	vim.notify('nvim-jdtls not installed', vim.log.levels.WARN)
return 
end

-- 1. Determine the project root
local root_markers = { 'gradlew', 'mvnw', 'pom.xml', 'build.gradle', '.git' }
local root_dir = require('jdtls.setup').find_root(root_markers) or vim.fn.getcwd()

-- 2. Unique WorkSpace per project
local workspace_dir = vim.fn.stdpath 'data' .. '/jdtls-wrkspaces/' .. vim.fn.fnamemodify(root_dir, ':p:h:t')
vim.fn.mkdir(workspace_dir, 'p')

-- 3. Mason Paths
local mason_base = vim.fn.stdpath 'data' .. '/mason/packages'
local jdtls_base = mason_base .. '/jdtls'
local launcher = vim.fn.glob(jdtls_base .. '/plugins/org.eclipse.equinox.launcher_*.jar')
local config_dir = jdtls_base .. '/config_mac'

-- Optional Lombok: 
-- local lombok_path = vim.fn.expand('~/.local/share/lombok/lombok.jar')

-- 4. Java command
local cmd = {
	'java',
	'-Declipse.application=org.eclipse.jdt.ls.core.id1',
	'-Dosgi.bundles.defaultStartLevel=4',
	'-Declipse.product=org.eclipse.jdt.ls.core.product',
	'-Dlog.protocol=true',
	'-Dlog.level=ALL',
	-- "javaagent:" .. lombok_path,
	 '-jar',
	 launcher,
	 '-configuration',
	config_dir,
	'-data',
workspace_dir,
}

-- 5. Capabilities (Blink aware) 
local capabilities = vim.lsp.protocol.make_client_capabilities()
local cmp_ok, cmp_lsp = pcall(require, 'cmp_nvim_lsp')
if cmp_ok then
  capabilities = cmp_lsp.default_capabilities(capabilities)
end

local settings = {
  java = {
    signatureHelp = { enabled = true },
    contentProvider = { preferred = 'fernflower' },
    completion = { favoriteStaticMembers = { 'org.assertj.core.api.Assertions.*', 'org.junit.jupiter.api.Assertions.*', 'org.mockito.Mockito.*' } },
    sources = { organizeImports = { starThreshold = 999, staticStarThreshold = 999 } },
    configuration = { updateBuildConfiguration = 'interactive' },
    maven = { downloadSources = true },
    eclipse = { downloadSources = true },
  }
}

local init_options = {
  bundles = {},
}

local on_attach = function(client, bufnr)
  local map = function(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
  end
  map('n', 'gd', vim.lsp.buf.definition, 'Goto Definition')
  map('n', 'K', vim.lsp.buf.hover, 'Hover')
  map('n', '<leader>rn', vim.lsp.buf.rename, 'Rename')
  map('n', '<leader>ca', vim.lsp.buf.code_action, 'Code Action')
  map('n', 'gr', vim.lsp.buf.references, 'References')
  map('n', '<leader>fo', function() vim.lsp.buf.format { async = true } end, 'Format')
  jdtls.setup_dap({ hotcodereplace = 'auto' })
  jdtls.setup.add_commands()
end

local config = {
  cmd = cmd,
  root_dir = root_dir,
  settings = settings,
  init_options = init_options,
  capabilities = capabilities,
  on_attach = on_attach,
}

jdtls.start_or_attach(config)
