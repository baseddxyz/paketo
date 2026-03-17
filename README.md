# Paketo

A Neovim configuration built around [mini.nvim](https://github.com/nvim-mini/mini.nvim).

## Requirements

- Neovim 0.12+ (development build)
- For Tree-sitter: C compiler (gcc/clang) for parser compilation

## Structure
```
├── init.lua            -- Entry point
├── plugin/│
│   ├── 10_options.lua  -- Neovim options
│   ├── 20_keymaps.lua  -- Key mappings
│   ├── 30_mini.lua     -- mini.nvim config
│   └── 40_plugins.lua  -- External plugins
├── after/              -- Filetype/LSP overrides
├── snippets/           -- User snippets
└── nvim-pack-lock.json -- Plugin lockfile
```

## Usage

Clone to your Neovim config directory:
```bash
git clone https://github.com/baseddxyz/paketo ~/.config/nvim
```

Update plugins with `:lua vim.pack.update()` then `:write` to confirm.

## License

O'Saasy
