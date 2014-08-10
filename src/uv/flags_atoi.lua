
--------------------------------------------------------------------------------
-- flags_atoi
--------------------------------------------------------------------------------

local flags_atoi = setmetatable({}, { __index = function(self, s)
  assert(type(s) == 'number', 'file flags should be "r", "w", "a", "r+", "w+", "a+", or a number')
  self[s] = s
  return s
end})

do
  local O_RDONLY    = 0x0000    -- open for reading only
  local O_WRONLY    = 0x0001    -- open for writing only
  local O_RDWR      = 0x0002    -- open for reading and writing
  local O_NONBLOCK  = 0x0004    -- no delay
  local O_APPEND    = 0x0008    -- set append mode
  local O_SHLOCK    = 0x0010    -- open with shared file lock
  local O_EXLOCK    = 0x0020    -- open with exclusive file lock
  local O_ASYNC     = 0x0040    -- signal pgrp when data ready
  local O_NOFOLLOW  = 0x0100    -- don't follow symlinks
  local O_CREAT     = 0x0200    -- create if nonexistant
  local O_TRUNC     = 0x0400    -- truncate to zero length
  local O_EXCL      = 0x0800    -- error if already exists

  flags_atoi['r'] = O_RDONLY
  flags_atoi['w'] = O_WRONLY + O_CREAT + O_TRUNC
  flags_atoi['a'] = O_WRONLY + O_CREAT + O_APPEND
  flags_atoi['r+'] = O_RDWR
  flags_atoi['w+'] = O_RDWR + O_CREAT + O_TRUNC
  flags_atoi['a+'] = O_RDWR + O_CREAT + O_APPEND
end

return flags_atoi
