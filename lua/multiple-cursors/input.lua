local M = {}

-- For checking if a character is a digit
local digits = {

  ["0"] = true,
  ["1"] = true,
  ["2"] = true,
  ["3"] = true,
  ["4"] = true,
  ["5"] = true,
  ["6"] = true,
  ["7"] = true,
  ["8"] = true,
  ["9"] = true,

}

-- Valid motion keys and their normal commands
local motions = {

  ["h"] = "h",
  ["\128kl"] = "h",  -- Left
  ["\128kb"] = "h",  -- Backspace
  ["j"] = "j",
  ["\128kd"] = "j",  -- Down
  ["k"] = "k",
  ["\128ku"] = "k",  -- Up
  ["l"] = "l",
  ["\128kr"] = "l",  -- Right
  [" "] = " ",       -- Space
  ["0"] = "0",
  ["\128kh"] = "0",  -- Home
  ["^"] = "^",
  ["$"] = "$",
  ["\128@7"] = "$",  -- End
  ["|"] = "|",
  ["-"] = "-",
  ["+"] = "+",
  ["\13"] = "+",
  ["_"] = "_",
  ["w"] = "w",
  ["\128%i"] = "w",     -- Shift+Right
  ["\128\253V"] = "w",  -- Ctrl+Right
  ["W"] = "W",
  ["e"] = "e",
  ["E"] = "E",
  ["b"] = "b",
  ["\128#4"] = "b",     -- Shift+Left
  ["\128\253U"] = "b",  -- Ctrl+Left
  ["B"] = "B",

}

-- Motion commands that need a following standard character
local search_motions = {
  ["f"] = true,
  ["F"] = true,
  ["t"] = true,
  ["T"] = true,
}

-- Get a standard character
-- Returns nil for anything else
-- ToDo check for escape, tab and enter?
function M.get_char()

  local char = vim.fn.getcharstr()
  if #char == 1 then
    return char
  else
    return nil
  end

end

-- Wait for a motion command
-- Returns a normal motion command (which may inclue a count) or nil if no valid
-- motion was given
function M.get_motion_char()

  -- Wait for a character
  local motion_char = vim.fn.getcharstr()

  local count = ""

  -- If the character is a digit
  while digits[motion_char] do
      -- Concatenate
      count = count .. motion_char

      -- Get another character
      motion_char = vim.fn.getcharstr()
  end

  -- If the character is a character search motion
  if search_motions[motion_char] then
    -- Wait for a printable character
    local char = M.get_char()

    if char then -- Valid character
      return count .. motion_char .. char
    else
      return nil
    end
  end

  -- If the character is a valid motion
  if motions[motion_char] then
    return count .. motions[motion_char]
  else
    return nil
  end

  return nil

end

return M
