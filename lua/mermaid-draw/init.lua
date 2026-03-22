local M = {}

-- State
local state = {
  panel_buf = nil,
  panel_win = nil,
  last_input = nil,  -- last mermaid code sent to backend
  last_output = {},  -- last successful ASCII art lines
  current_job = nil,
}

-- Default config
local default_config = {
  backend = "binary",
  binary_path = "mermaid-ascii",
  binary_opts = {},
  panel_width = nil,  -- fixed width in columns; nil = auto (1/3 of screen, min 40)
  clear_on_leave = false,  -- clear panel when cursor leaves a mermaid block
  keymaps = {
    toggle = "<leader>mm",
  },
  updatetime = 500,
}

M.config = vim.deepcopy(default_config)

-- Find the mermaid code block at the cursor position.
-- Returns the content string, or nil if cursor is not inside a mermaid block.
local function find_mermaid_block()
  local buf = vim.api.nvim_get_current_buf()
  local row = vim.api.nvim_win_get_cursor(0)[1]  -- 1-indexed
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

  local start_row = nil
  for i = 1, #lines do
    if lines[i]:match("^```mermaid%s*$") then
      start_row = i
    elseif start_row and lines[i]:match("^```%s*$") then
      local end_row = i
      if row >= start_row and row <= end_row then
        local block = {}
        for j = start_row + 1, end_row - 1 do
          table.insert(block, lines[j])
        end
        return table.concat(block, "\n")
      end
      start_row = nil
    end
  end
  return nil
end

-- Panel helpers

local function panel_width()
  if M.config.panel_width then
    return M.config.panel_width
  end
  return math.max(40, math.floor(vim.o.columns / 3))
end

local function is_panel_open()
  return state.panel_win ~= nil and vim.api.nvim_win_is_valid(state.panel_win)
end

local function create_panel()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].modifiable = false
  state.panel_buf = buf

  local win = vim.api.nvim_open_win(buf, false, {
    split = "right",
    width = panel_width(),
  })
  vim.wo[win].wrap = false
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].signcolumn = "no"
  state.panel_win = win
end

local function close_panel()
  if is_panel_open() then
    vim.api.nvim_win_close(state.panel_win, true)
  end
  state.panel_win = nil
  state.panel_buf = nil
end

local function set_panel_lines(lines)
  if not is_panel_open() then return end
  vim.bo[state.panel_buf].modifiable = true
  vim.api.nvim_buf_set_lines(state.panel_buf, 0, -1, false, lines)
  vim.bo[state.panel_buf].modifiable = false
end

function M.toggle()
  if is_panel_open() then
    close_panel()
  else
    create_panel()
  end
end

-- Binary backend

local function render_binary(content, callback)
  local cmd = { M.config.binary_path }
  for _, opt in ipairs(M.config.binary_opts) do
    table.insert(cmd, opt)
  end

  return vim.system(cmd, { stdin = content }, function(result)
    vim.schedule(function()
      callback(result)
    end)
  end)
end

-- Main render trigger

function M.render()
  if not is_panel_open() then return end

  local content = find_mermaid_block()
  if content == nil then
    if M.config.clear_on_leave then
      state.last_input = nil
      state.last_output = {}
      set_panel_lines({})
    end
    return
  end

  -- Diff check: skip if content hasn't changed
  if content == state.last_input then return end

  -- Kill previous job if still running
  if state.current_job then
    state.current_job:kill(9)
    state.current_job = nil
  end

  local function on_result(result)
    state.current_job = nil
    if result.code == 0 then
      state.last_input = content
      local output = vim.split(result.stdout, "\n", { plain = true })
      -- Strip trailing empty lines
      while #output > 0 and output[#output] == "" do
        table.remove(output)
      end
      state.last_output = output
      set_panel_lines(output)
    else
      -- Show error at top, keep last successful output below
      local err_msg = vim.trim(result.stderr or "unknown error")
      local lines = { "-- ERROR: " .. err_msg, "" }
      for _, l in ipairs(state.last_output) do
        table.insert(lines, l)
      end
      set_panel_lines(lines)
    end
  end

  if M.config.backend == "binary" then
    state.current_job = render_binary(content, on_result)
  end
end

-- Autocmds per markdown buffer

local function setup_buffer_autocmds(buf)
  local group = vim.api.nvim_create_augroup("MermaidDraw_buf_" .. buf, { clear = true })
  vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
    buffer = buf,
    group = group,
    callback = M.render,
  })
end

-- Setup

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", default_config, opts or {})

  -- Apply updatetime only if the current value is larger (don't override a tighter setting)
  if vim.o.updatetime > M.config.updatetime then
    vim.o.updatetime = M.config.updatetime
  end

  -- Watch markdown buffers
  local group = vim.api.nvim_create_augroup("MermaidDraw", { clear = true })
  vim.api.nvim_create_autocmd("BufEnter", {
    group = group,
    callback = function(ev)
      if vim.bo[ev.buf].filetype == "markdown" then
        setup_buffer_autocmds(ev.buf)
      end
    end,
  })

  -- Command
  vim.api.nvim_create_user_command("MermaidToggle", M.toggle, {})

  -- Keymap
  local toggle_key = M.config.keymaps and M.config.keymaps.toggle
  if toggle_key and toggle_key ~= false then
    vim.keymap.set("n", toggle_key, M.toggle, { desc = "Toggle Mermaid ASCII preview" })
  end
end

return M