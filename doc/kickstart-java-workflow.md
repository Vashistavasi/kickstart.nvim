# Kickstart Neovim Walkthrough

## Boot Order
- [`init.lua`](/Users/vasi/.config/nvim/init.lua) runs first.
- The top of `init.lua` sets leader keys, editor options, basic keymaps, and early autocmds.
- `lazy.nvim` is then bootstrapped and added to the runtimepath.
- `require('lazy').setup(...)` defines the core Kickstart plugins inside `init.lua`.
- Extra Kickstart modules are required near the end of `init.lua`, such as debug, lint, autopairs, indent guides, and gitsigns.
- `{ import = 'custom.plugins' }` loads every file from [`lua/custom/plugins`](/Users/vasi/.config/nvim/lua/custom/plugins).
- Filetype-specific runtime hooks in `after/` would run last. Java no longer starts from `after/ftplugin`; it now starts only from [`lua/custom/plugins/nvim-jdtls.lua`](/Users/vasi/.config/nvim/lua/custom/plugins/nvim-jdtls.lua).

## Where Your Features Live
- Core editor behavior: [`init.lua`](/Users/vasi/.config/nvim/init.lua)
- Java language server and Java debugging: [`lua/custom/plugins/nvim-jdtls.lua`](/Users/vasi/.config/nvim/lua/custom/plugins/nvim-jdtls.lua)
- File tree: [`lua/custom/plugins/neo-tree.lua`](/Users/vasi/.config/nvim/lua/custom/plugins/neo-tree.lua)
- Generic debugger UI and non-Java adapters: [`lua/kickstart/plugins/debug.lua`](/Users/vasi/.config/nvim/lua/kickstart/plugins/debug.lua)

## Add Or Remove Plugins
- Add a plugin directly in [`init.lua`](/Users/vasi/.config/nvim/init.lua) if it belongs with the base Kickstart stack.
- Add a plugin under [`lua/custom/plugins`](/Users/vasi/.config/nvim/lua/custom/plugins) if it is your customization.
- A plugin file should return a Lazy spec table.
- Inspect plugin state with `:Lazy`.
- Update plugins with `:Lazy update`.
- Remove a plugin by deleting its Lazy spec and then running `:Lazy clean`.
- Inspect language tools with `:Mason`.

## Interactive Tutor
- Run `:KickstartTutor` to open the built-in 60-minute guided practice buffer.
- Run `:KickstartTutorReset` to rebuild the generated practice workspace under `/Users/vasi/.local/share/nvim/kickstart-tutor`.
- Inside the tutor buffer, press `<CR>` on action lines, `x` on checklist items, `R` to reset the workspace, and `q` to close the buffer.

## Shortcut Sheet
- Core:
  - `<Esc>` clears search highlight
  - `<Esc><Esc>` exits terminal mode
  - `<C-h> <C-j> <C-k> <C-l>` move between splits
- Telescope:
  - `<leader>sh` help tags
  - `<leader>sk` keymaps
  - `<leader>sf` files
  - `<leader>ss` Telescope builtins
  - `<leader>sw` word under cursor
  - `<leader>sg` live grep
  - `<leader>sd` diagnostics
  - `<leader>sr` resume last picker
  - `<leader>s.` recent files
  - `<leader><leader>` buffers
  - `<leader>/` fuzzy search current buffer
  - `<leader>s/` grep only open files
  - `<leader>sn` search your Neovim config
- LSP and diagnostics:
  - `grn` rename
  - `gra` code action
  - `grr` references
  - `gri` implementation
  - `grd` definition
  - `grD` declaration
  - `grt` type definition
  - `gO` document symbols
  - `gW` workspace symbols
  - `[d ]d` previous and next diagnostic
  - `[D ]D` first and last diagnostic
  - `<leader>q` diagnostics to location list
  - `<leader>th` toggle inlay hints when supported
- Neo-tree:
  - `\` reveal current file in tree
  - `<leader>e` toggle or focus tree
  - Inside the tree: `s` split, `v` vsplit, `h` collapse, `l` open, `/` fuzzy find, `#` fuzzy find in directory, `<space>` preview, `P` floating preview
- Git:
  - `]c [c` next and previous hunk
  - `<leader>hs` stage hunk
  - `<leader>hr` reset hunk
  - `<leader>hS` stage buffer
  - `<leader>hu` undo staged hunk
  - `<leader>hR` reset buffer
  - `<leader>hp` preview hunk
  - `<leader>hb` blame line
  - `<leader>hd` diff against index
  - `<leader>hD` diff against last commit
  - `<leader>tb` toggle current line blame
  - `<leader>tD` preview deleted text inline
- Formatting and completion:
  - `<leader>f` format buffer
  - Blink completion uses `<C-space>`, `<C-n>`, `<C-p>`, `<C-e>`, `<C-k>`, `<Tab>`, and `<S-Tab>`
- Debugging:
  - `<F5>` start or continue
  - `<F1>` step into
  - `<F2>` step over
  - `<F3>` step out
  - `<leader>b` toggle breakpoint
  - `<leader>B` conditional breakpoint
  - `<F7>` toggle DAP UI
- Java:
  - `<leader>jC` open a Java class by name
  - `<leader>jc` debug current main class
  - `<leader>jt` debug current test class
  - `<leader>jn` debug nearest test method
  - `<leader>jo` organize imports

## Java Workflow
- Open a Java file inside a Maven or Gradle project and JDTLS attaches to the project root automatically.
- Open a standalone Java file and JDTLS uses that file’s directory as the root instead of Neovim’s working directory.
- Java debug/test bundles are loaded from Mason.
- Java DAP and Java-specific keymaps are configured from one place only.

## 1-Hour Interactive Session
- `00-10`: movement refresh with `f/F/t/T`, `;`, `%`, `*`, `#`, marks, jumplist
- `10-20`: editing fluency with text objects, `ci`, `da`, dot-repeat, registers, macros, and `mini.surround`
- `20-30`: project navigation with Neo-tree, buffers, Telescope file search, live grep, and symbols
- `30-40`: code intelligence with definitions, references, rename, code actions, diagnostics, formatting, quickfix, and location list
- `40-50`: git and debugging with hunks, breakpoints, stepping, and DAP UI
- `50-60`: Java drill with open class, rename, organize imports, debug main, and debug nearest test

## Daily 15-Minute Loop
- `05m`: movement-only editing without touching arrow keys
- `05m`: project search and LSP navigation
- `05m`: one real refactor, test debug, or code-reading session
