# mermaid-draw

A Neovim plugin that renders Mermaid diagrams as ASCII art in a side panel.

## File Structure

```
lua/mermaid-draw/init.lua   - Main plugin logic (M.setup, M.render, M.toggle)
plugin/mermaid-draw.lua     - Entry point (guards double-loading)
test/sample.md              - Sample markdown file for manual testing
```

## Architecture

- Triggers on `CursorHold` / `CursorHoldI` in markdown buffers
- Extracts the mermaid code block under the cursor
- Skips rendering if content hasn't changed (diff check against `state.last_input`)
- Kills the previous async job before starting a new one
- Calls the backend (`mermaid-ascii` binary via stdin) asynchronously with `vim.system`
- Updates the right side panel buffer in one shot on success
- On error: shows the error at the top, keeps the last successful output below

## Key State (`state` table in init.lua)

- `panel_buf` / `panel_win` — side panel buffer and window handles
- `last_input` — last mermaid source sent to the backend (for diff check)
- `last_output` — last successful ASCII art lines
- `current_job` — handle of the running `vim.system` job

