# AGENTS.md

Guidance for AI agents working with the Paketo Neovim configuration.

## Project Overview

Paketo is a Neovim configuration built around [mini.nvim](https://github.com/nvim-mini/mini.nvim). It targets **Neovim 0.12+** (development build) and uses the built-in `vim.pack` plugin manager with a lockfile (`nvim-pack-lock.json`).

## Architecture

```
init.lua                Entry point — plugin manager bootstrap, global helpers (_G.Config)
plugin/
  10_options.lua        Neovim options (vim.o), diagnostics config, autocommands
  20_keymaps.lua        General and <Leader> key mappings
  30_mini.lua           mini.nvim module setup (colorscheme, statusline, completion, etc.)
  40_plugins.lua        External plugins (tree-sitter, LSP, formatting, snippets, fzf-lua, fff.nvim)
after/
  ftplugin/             Buffer-local filetype overrides (e.g. markdown.lua)
  lsp/                  Per-server LSP configs (e.g. lua_ls.lua)
  snippets/             Per-language snippet overrides (e.g. lua.json)
snippets/
  global.json           Snippets available in every buffer
nvim-pack-lock.json     Plugin version lockfile (pins commit SHAs)
mise.toml               Tool versions (LuaLS, ty)
```

### Loading Model

`init.lua` defines helpers that control when code runs during startup:

- `Config.now(fn)` — execute immediately (startup-critical: colorscheme, statusline, tabline, starter, icons, notify, sessions)
- `Config.later(fn)` — defer until after first screen draw (most mini modules, external plugins)
- `Config.now_if_args(fn)` — `now` when Neovim opens files (`nvim -- file`), `later` otherwise (completion, mini.files, mini.misc)
- `Config.on_event(ev, fn)` — defer until first occurrence of an event
- `Config.on_filetype(ft, fn)` — defer until first occurrence of a filetype

### Global State

`_G.Config` is a shared table available as `Config` across all config files. It carries loading helpers, the `new_autocmd` wrapper, and `on_packchanged` for plugin lifecycle hooks.

## Key Conventions

### Lua Style

- 2-space indentation; `shiftwidth = 2`, `tabstop = 2`, `expandtab = true`.
- `-- stylua: ignore start` / `-- stylua: ignore end` guards for manually aligned blocks — preserve these.
- Comments are extensive and didactic (aimed at the user reading files inside Neovim). Preserve their style and detail level.
- Module setup follows `require('mini.xxx').setup({ ... })` pattern.

### Key Mappings

- Leader is `<Space>` (`vim.g.mapleader = ' '`).
- Two-key leader scheme: first key = semantic group, second key = action.
  - `b` buffer, `e` explore/edit, `f` fuzzy find, `g` git, `l`/`ca`/`cd`/`fm`/`rn` LSP, `m` map, `o` other, `s` session, `t` terminal, `v` visits.
- Leader mappings use `<Cmd>...<CR>` RHS strings for lazy loading (no requirement that the underlying command exists at mapping creation time).
- Non-leader mappings: `gd`, `gD`, `gr`, `gi`, `K`, `<C-k>`, `<Tab>`/`<S-TAB>` buffer nav, `[p`/`]p` linewise paste.

### Plugin Management

- Uses Neovim 0.12's built-in `vim.pack` — NOT a third-party plugin manager.
- Plugins are added with `vim.pack.add({ 'https://github.com/...' })`.
- Lockfile `nvim-pack-lock.json` tracks pinned commit SHAs. Do not edit manually; update via `:lua vim.pack.update()` then `:write`.
- External plugins: `mini.nvim`, `nvim-treesitter`, `nvim-treesitter-textobjects`, `nvim-lspconfig`, `conform.nvim`, `friendly-snippets`, `fzf-lua`, `fff.nvim`.

### LSP

- Uses `vim.lsp.enable()` and `vim.lsp.config()` (Neovim 0.12 built-in API).
- Per-server configs live in `after/lsp/` as Lua modules returning config tables.
- Currently enabled servers: `lua_ls` (via `mise`), `ty`.

### Formatting

- `conform.nvim` handles formatting with `lsp_format = "fallback"`.
- Format mappings: `<Leader>fm` (buffer), `<Leader>lf` (visual selection).
- Formatter configs are in `formatters_by_ft` inside `plugin/40_plugins.lua`.

### Snippets

- `mini.snippets` manages snippet loading and expansion.
- Sources: `snippets/global.json` (always loaded), `after/snippets/<lang>.json` (per-language), `friendly-snippets` plugin collection.
- Expand with `<C-j>`, navigate tabstops with `<C-l>`/`<C-h>`.

### Tree-sitter

- Languages configured in `plugin/40_plugins.lua` (`languages` table).
- Auto-installs missing parsers on startup.
- Tree-sitter used for: syntax highlighting, textobjects (`MiniAi.gen_spec.treesitter`), fold expressions (e.g. markdown).

## Filetype-Specific Notes

- **Markdown** (`after/ftplugin/markdown.lua`): enables spell check, wrap, tree-sitter folding; adds custom `L` surrounding for markdown links.
- **Lua** (`after/snippets/lua.json`): provides `l` prefix snippet for `local` declarations.

## Making Changes

### Adding a mini.nvim module

1. Add `require('mini.xxx').setup({ ... })` in `plugin/30_mini.lua`.
2. Choose the right loading stage (`now`, `now_if_args`, or `later`).
3. Add leader mappings in `plugin/20_keymaps.lua` if applicable.

### Adding an external plugin

1. Add `vim.pack.add({ 'url' })` in `plugin/40_plugins.lua`.
2. Use `Config.on_packchanged(name, kinds, fn)` for post-install/update hooks.
3. Restart Neovim, then `:lua vim.pack.update()` to install.

### Adding a language server

1. Install the server binary externally (system package manager, `mise`, etc.).
2. Create `after/lsp/<server_name>.lua` returning a config table.
3. Add `vim.lsp.enable('<server_name>')` in `plugin/40_plugins.lua`.

### Adding a formatter

1. Install the formatter binary.
2. Add entry to `formatters_by_ft` in `plugin/40_plugins.lua`.

### Adding tree-sitter languages

1. Append the language name to the `languages` table in `plugin/40_plugins.lua`.
2. Restart Neovim — parser installs automatically.

## Common Commands

| Action | Command |
|---|---|
| Update plugins | `:lua vim.pack.update()` then `:write` |
| Delete a plugin | `:lua vim.pack.del({ 'name' })` |
| Check tree-sitter health | `:checkhealth vim.treesitter nvim-treesitter` |
| Install TS parser | `:TSInstall <lang>` |
| Format buffer | `<Leader>fm` |
| LSP info | `:LspInfo` |

## Diagnostics

Diagnostics are configured conservatively in `plugin/10_options.lua`:
- Signs shown for warnings and errors only.
- Underline for all severity levels.
- Virtual text on current line for errors only.
- Diagnostics do not update in insert mode.
