# chchchanges.nvim

A Neovim plugin that analyzes git changes in your repository and populates the quickfix list with individual git hunks.

## Features

- = Parses `git diff` output to extract hunks
- =� Populates quickfix list with proper formatting
- � Lazy-loaded for minimal startup impact
- =' Configurable via `vim.g` variables
- =� LuaCATS type annotations for better IDE support
- <� No `setup()` function required - works out of the box

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  'yourusername/chchchanges.nvim',
  cmd = 'ChChanges', -- Lazy load on command
  keys = {
    { '<leader>gc', '<cmd>ChChanges<cr>', desc = 'Show git changes' },
  },
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  'yourusername/chchchanges.nvim',
  cmd = 'ChChanges',
}
```

### Using [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'yourusername/chchchanges.nvim'
```

## Usage

### Commands

- `:ChChanges` - Populate quickfix with git hunks and open the quickfix window
- `:ChChanges!` - Populate quickfix with git hunks without opening the window

### Keymappings

```lua
-- Show git changes in quickfix
vim.keymap.set('n', '<leader>gc', '<cmd>ChChanges<cr>', { desc = 'Show git changes' })

-- Load git changes without opening quickfix
vim.keymap.set('n', '<leader>gC', '<cmd>ChChanges!<cr>', { desc = 'Load git changes' })
```

### Lua API

```lua
-- Populate and open quickfix
require('chchchanges').populate_quickfix()

-- Populate without opening
require('chchchanges').populate_quickfix({ open = false })

-- Append to existing quickfix list
require('chchchanges').populate_quickfix({ action = 'a' })
```

## Configuration

Configuration is done via `vim.g` variables. No `setup()` function is required.

```lua
-- Custom git command (default: 'git')
vim.g.chchchanges_git_cmd = '/usr/local/bin/git'

-- Additional git diff arguments (default: {})
vim.g.chchchanges_diff_args = { '--cached' } -- Show staged changes only
```

### Configuration Examples

```lua
-- Show only staged changes
vim.g.chchchanges_diff_args = { '--cached' }

-- Show changes with more context
vim.g.chchchanges_diff_args = { '-U5' }

-- Compare against a specific branch
vim.g.chchchanges_diff_args = { 'main' }
```

## How It Works

1. Runs `git diff` in the current repository (unstaged changes by default)
2. Parses the diff output to extract hunk headers (`@@ ... @@`)
3. Creates quickfix entries for each hunk with:
   - File path
   - Line number where the hunk starts
   - Context (function/class name if available)
4. Populates the quickfix list with proper formatting

## Development

This plugin follows the [Neovim Lua plugin best practices](https://github.com/lumen-oss/nvim-best-practices):

-  LuaCATS type annotations
-  No mandatory `setup()` function
-  Lazy initialization via `plugin/` directory
-  Configuration via `vim.g` global variables
-  Proper quickfix formatting

## License

MIT

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
