local M = {}

local common = require("multiple-cursors.common")
local virtual_cursors = require("multiple-cursors.virtual_cursors")


-- Right -----------------------------------------------------------------------

-- Right command for a virtual cursor
local function virtual_cursor_right(vc, count)
  count = vim.fn.max({count, 1})
  local col = vc.col + count
  vc.col = common.get_col(vc.lnum, col)
  vc.curswant = vc.col
end

-- Right command for all virtual cursors
-- This isn't local because it's used in normal_to_insert
function M.all_virtual_cursors_right(count)
  virtual_cursors.visit_in_buffer(function(vc) virtual_cursor_right(vc, count) end)
end

-- l command in normal/visual modes
function M.normal_l()
  common.feedkeys("l", vim.v.count)
  M.all_virtual_cursors_right(vim.v.count)
end

-- Right in insert/replace modes
function M.insert_right()
  common.feedkeys("<Right>", 0)
  M.all_virtual_cursors_right(0)
end


-- End-of-line -----------------------------------------------------------------

-- End-of-Line command for a virtual cursor
-- This isn't local because it's used by normal_to_insert
function M.virtual_cursor_end(vc)
  vc.col = common.get_col(vc.lnum, vim.v.maxcol)
  vc.curswant = vim.v.maxcol
end

-- End-of-Line command for all virtual cursors
-- This isn't local because it's used by normal_to_insert
function M.all_virtual_cursors_end()
  virtual_cursors.visit_in_buffer(function(vc) M.virtual_cursor_end(vc) end)
end

-- $ command in normal/visual modes
function M.normal_dollar()
  common.feedkeys("$", 0)
  M.all_virtual_cursors_end()
end

-- EoL command in all modes
function M.eol()
  common.feedkeys("<End>", 0)
  M.all_virtual_cursors_end()
end


-- Up --------------------------------------------------------------------------

-- Determine the amount the real cursor will actually move up
local function get_actual_count_up(count)
  count = vim.fn.max({count, 1})
  local cursor_lnum = vim.fn.getcursorcharpos()[2]
  return vim.fn.min({count, cursor_lnum - 1})
end

-- Up command for a virtual cursor
local function virtual_cursor_up(vc, count)
  -- Set virtual cursor lnum
  vc.lnum = vc.lnum - count

  -- If the cursor is out of the buffer
  if vc.lnum < 1 then
    vc.within_buffer = false
  elseif vc.lnum <= vim.fn.line("$") then
    vc.within_buffer = true
    vc.col = common.get_col(vc.lnum, vc.curswant)
  end
end

-- Up command for all virtual cursors
local function all_virtual_cursors_up(count)
  count = get_actual_count_up(count)
  virtual_cursors.visit_all(function(vc) virtual_cursor_up(vc, count) end)
end

-- Up command
function M.normal_k()
  common.feedkeys("k", vim.v.count)
  all_virtual_cursors_up(vim.v.count)
end

function M.insert_up()
  common.feedkeys("<Up>", 0)
  all_virtual_cursors_up(0)
end


-- Down ------------------------------------------------------------------------

-- Determine the amount the real cursor will actually move down
local function get_actual_count_down(count)
  count = vim.fn.max({count, 1})
  local cursor_lnum = vim.fn.getcursorcharpos()[2]
  local num_lines = vim.fn.line("$")
  return vim.fn.min({count, num_lines - cursor_lnum})
end

-- Down command for a virtual cursor
local function virtual_cursor_down(vc, count)
  -- Set virtual cursor lnum
  vc.lnum = vc.lnum + count

  -- If the cursor is out of the buffer
  if vc.lnum > vim.fn.line("$") then
    vc.within_buffer = false
  elseif vc.lnum >= 1 then
    vc.within_buffer = true
    vc.col = common.get_col(vc.lnum, vc.curswant)
  end
end

-- Down command for all virtual cursors
local function all_virtual_cursors_down(count)
  count = get_actual_count_down(count)
  virtual_cursors.visit_all(function(vc) virtual_cursor_down(vc, count) end)
end

function M.normal_j()
  common.feedkeys("j", vim.v.count)
  all_virtual_cursors_down(vim.v.count)
end

function M.insert_down()
  common.feedkeys("<Down>", 0)
  all_virtual_cursors_down(0)
end


-- Composite -------------------------------------------------------------------
-- Funtions that can also change lines

-- Normal mode backspace command for a vritual cursor
local function virtual_cursor_normal_backspace(vc, count)

  while count > 0 do

    -- No line change
    if vc.col > count then
      vc.col = vc.col - count
      vc.curswant = vc.col
      return
    end

    -- First line, go to first column
    if vc.lnum == 1 then
      vc.col = 1
      vc.curswant = vc.col
      return
    end

    count = count - vc.col
    vc.lnum = vc.lnum - 1
    vc.col = common.get_max_col(vc.lnum)
  end

  vc.curswant = vc.col

end

-- Normal mode backspace command for all virtual cursors
local function all_virtual_cursors_normal_backspace(count)
  count = vim.fn.max({count, 1})
  virtual_cursors.visit_in_buffer(function(vc) virtual_cursor_normal_backspace(vc, count) end)
end

-- Normal mode backspace command
function M.normal_bs()
  common.feedkeys("<BS>", vim.v.count)
  all_virtual_cursors_normal_backspace(vim.v.count)
end

-- Normal mode -: up N lines to first non-blank character
function M.normal_minus()
  common.feedkeys("-", vim.v.count)
  all_virtual_cursors_up(vim.v.count)
  virtual_cursors.move_with_normal_command("^", 0)
end

-- Normal mode +: down N lines to first non-blank character
function M.normal_plus() -- Also <CR> and <kEnter>
  common.feedkeys("+", vim.v.count)
  all_virtual_cursors_down(vim.v.count)
  virtual_cursors.move_with_normal_command("^", 0)
end

-- Normal mode _: down N-1 lines to first non-blank character
function M.normal_underscore()
  if vim.v.count <= 1 then
    common.feedkeys("_", vim.v.count)
    virtual_cursors.move_with_normal_command("_", vim.v.count)
  else
    common.feedkeys("_", vim.v.count)
    all_virtual_cursors_down(vim.v.count - 1)
    virtual_cursors.move_with_normal_command("^", 0)
  end
end

-- Normal mode $: EoL or down N lines to EoL
function M.normal_dollar()
  -- End of current line
  if vim.v.count <= 1 then
    common.feedkeys("$", vim.v.count)
    virtual_cursors.move_with_normal_command("$", vim.v.count)
  else -- Down N-1 lines
    common.feedkeys("$", vim.v.count)
    all_virtual_cursors_down(vim.v.count - 1)
    virtual_cursors.move_with_normal_command("$", 0)
  end
end

return M
