# version-lens.nvim

A Neovim plugin that displays installed package versions as virtual text in package.json files.

## Features

- Shows actual installed versions next to package dependencies in package.json
- Supports multiple package managers (npm, yarn, pnpm)
- Automatically detects the package manager based on lock files
- Updates on file load
- Zero configuration required

## Requirements

- Neovim >= 0.8.0
- One of the following package managers installed:
  - npm
  - yarn
  - pnpm

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
    "danitrap/version-lens.nvim",
    config = true
}
```

## Usage

The plugin automatically activates when opening a `package.json` file. It will:

1. Detect your package manager (npm, yarn, or pnpm)
2. Fetch currently installed versions
3. Display versions as virtual text at the end of each dependency line

Example:

```json
{
  "dependencies": {
    "express": "^4.17.1",  4.17.3
    "lodash": "~4.17.21"  4.17.21
  }
}
```

## Configuration

No configuration needed! The plugin works out of the box.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT License - see [LICENSE](LICENSE) for details
