local M = {}

local common = require("multiple-cursors.common")
local virtual_cursors = require("multiple-cursors.virtual_cursors")
local visual_mode = require("multiple-cursors.visual_mode")

local enable_split_paste = nil
local original_paste_function = nil

function M.setup(_enable_split_paste)
  enable_split_paste = _enable_split_paste
end

-- Paste in normal mode for a virtual cursor
local function virtual_cursor_normal_mode_paste(lines, vc)
  local move_afterwards = vc.col < common.get_max_col(vc.lnum)

  -- Put the line(s) after the cursor
  vim.api.nvim_put(lines, "c", true, true)

  if move_afterwards then
    vim.cmd("normal! h")
  end
end

-- Paste in insert mode for a virtual cursor
local function virtual_cursor_insert_mode_paste(lines, vc)
  -- Put the line(s) before the cursor
  vim.api.nvim_put(lines, "c", false, true)
end

-- Paste in replace mode for a virtual cursor
local function virtual_cursor_replace_mode_paste(lines, vc)

  -- If the cursor is at the end of the line
  if vc.col == common.get_max_col(vc.lnum) then
    -- Put paste lines before the cursor
    vim.api.nvim_put(lines, "c", false, false)
  else -- Cursor not at the end of the line
    -- If there are multiple paste lines
    if #lines ~= 1 then
      -- Delete to the end of the line and put paste lines after the cursor
      vim.cmd("normal! \"_D")
      vim.api.nvim_put(lines, "c", true, false)
    else -- Single paste line
      local paste_line_length = #lines[1]
      local overwrite_length = common.get_length_of_line(vc.lnum) - vc.col + 1

      -- The length of the paste line is less than being overwritten
      if paste_line_length < overwrite_length then
        -- Delete the paste line length and put the paste line before the cursor
        vim.cmd("normal! \"_" .. tostring(paste_line_length) .. "dl")
        vim.api.nvim_put(lines, "c", false, false)
      else
        -- Delete to the end of the line and put paste line after the cursor
        vim.cmd("normal! \"_D")
        vim.api.nvim_put(lines, "c", true, false)
      end
    end
  end

end

-- Paste handler
local function paste(lines)

  local split_paste = enable_split_paste and virtual_cursors.can_split_paste(#lines)

  if split_paste then
    -- Reorder lines
    virtual_cursors.reorder_lines_for_split_pasting(lines)
  end

  local func = nil
  local set_position = true

  -- Set the function to call
  if common.is_mode("n") then
    func = virtual_cursor_normal_mode_paste
  elseif common.is_mode("i") then
    func = virtual_cursor_insert_mode_paste
  elseif common.is_mode("R") then
    func = virtual_cursor_replace_mode_paste
    set_position = false
  elseif common.is_mode("v") then
    -- Paste is handled by the visual_mode module so it can be performed after
    -- exiting visual mode
    visual_mode.paste_on_exit(split_paste, lines)
  end

  if func then
    virtual_cursors.edit_with_cursor(function(vc, idx)

      if split_paste then
        func({lines[idx]}, vc)
      else
        func(lines, vc)
      end

      if set_position then
        common.set_virtual_cursor_from_cursor(vc)
      end

    end)
  end

  if split_paste then
    -- Return the last line for pasting to the real cursor
    return {lines[#lines]}
  else
    -- Return the original lines for pasting to the real cursor
    return lines
  end

end

-- Override the paste handler
function M.override_handler()

  -- Save the original paste handler
  original_paste_function = vim.paste

  -- Override
  vim.paste = (function(overridden)
      return function(lines, phase)
        return overridden(paste(lines), phase)
      end
  end)(vim.paste)
end

-- Revert the paste handler
function M.revert_handler()
  vim.paste = original_paste_function
end

return M
