# mermaid-draw

A Neovim plugin that renders Mermaid diagrams as ASCII art in real time.

```
┌────────┐     ┌────────┐
│ Client │     │ Server │
└───┬────┘     └───┬────┘
    │              │
    │   Request    │
    ├─────────────►│
    │              │
    │   Response   │
    │◄┈┈┈┈┈┈┈┈┈┈┈┈┈┤
    │              │
```

## Features

- Detects ` ```mermaid ``` ` blocks in Markdown files
- Displays ASCII art in a right-side panel when the cursor is inside a block
- Flicker-free asynchronous rendering
- Toggle the panel with `:MermaidToggle`

## Requirements

- Neovim 0.10+
- [mermaid-ascii](https://github.com/AlexanderGrooff/mermaid-ascii) (CLI tool written in Go)

## Installation

### 1. Install mermaid-ascii

Requires Go.

```sh
go install github.com/AlexanderGrooff/mermaid-ascii@latest
```

### 2. Install the plugin

**lazy.nvim** (adding `build` will automatically install `mermaid-ascii` as well)

```lua
{
  "icck/mermaid-draw",
  build = "go install github.com/AlexanderGrooff/mermaid-ascii@latest",
  ft = "markdown",
  config = function()
    require('mermaid-draw').setup()
  end,
}
```

**Other plugin managers**

Install `mermaid-ascii` manually, then add the following to your config:

```lua
require('mermaid-draw').setup()
```

## Configuration

All options are optional.

```lua
require('mermaid-draw').setup({
  -- Backend: "binary" (default)
  backend = "binary",

  -- Path to the mermaid-ascii binary (defaults to searching PATH)
  binary_path = "mermaid-ascii",

  -- Additional options passed to mermaid-ascii
  -- -x: horizontal spacing between nodes (default 5)
  -- -y: vertical spacing between nodes (default 5)
  -- -p: box padding (default 1)
  -- --ascii: use ASCII characters instead of Unicode
  binary_opts = {},

  -- updatetime (ms): how long to wait before CursorHold fires
  updatetime = 500,

  -- Keymaps (set to false to disable)
  keymaps = {
    toggle = "<leader>mm",
  },
})
```

## Usage

1. Open a Markdown file
2. Open the right-side panel with `<leader>mm` (or `:MermaidToggle`)
3. Move the cursor inside a ` ```mermaid ``` ` block
4. Wait a moment (500ms by default) for the ASCII art to appear

The panel stays open when the cursor leaves the block, keeping the last preview visible.
If there are multiple mermaid blocks, the one under the cursor is displayed.

## Supported Diagrams

Only diagrams supported by `mermaid-ascii` are available.

| Diagram | Support |
|---------|---------|
| Flowchart (`graph LR` / `graph TD`) | ✅ |
| Sequence diagram (`sequenceDiagram`) | ✅ |
| Others | ❌ |

> **Note**: Complex path crossings and diagonal arrows may not render correctly due to limitations in `mermaid-ascii`.

## License

MIT