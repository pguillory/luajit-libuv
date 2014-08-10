local uv = require 'uv'
local class = require 'class'
local ffi = require 'ffi'

ffi.cdef [[
  mode_t umask(mode_t mask);
]]
-- ffi.C.umask(0)


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

--------------------------------------------------------------------------------
-- mode_atoi
--------------------------------------------------------------------------------

local mode_atoi = setmetatable({}, { __index = function(self, s)
  local i
  if type(s) == 'string' then
    if #s == 3 then
      i = 0
      local function octal_digit(index, value)
        local n = tonumber(s:sub(index, index))
        if n >= 0 and n <= 7 then
          i = i + n * value
        else
          error('file modes look like: "755" or "rwxr-xr-x"')
        end
      end
      octal_digit(1, 64)
      octal_digit(2, 8)
      octal_digit(3, 1)
    elseif #s == 9 then
      i = 0
      local function match_char(index, expected_char, n)
        local char = s:sub(index, index)
        if char == expected_char then
          i = i + n
        elseif char ~= '-' then
          error('file modes look like: "755" or "rwxr-xr-x"')
        end
      end
      match_char(1, 'r', 256)
      match_char(2, 'w', 128)
      match_char(3, 'x', 64)
      match_char(4, 'r', 32)
      match_char(5, 'w', 16)
      match_char(6, 'x', 8)
      match_char(7, 'r', 4)
      match_char(8, 'w', 2)
      match_char(9, 'x', 1)
    else
      error('file modes look like: "755" or "rwxr-xr-x"')
    end
  elseif type(s) == 'number' then
    i = s
  else
    error('unexpected mode type: ' .. type(s))
  end
  self[s] = i
  return i
end})

do
  assert(mode_atoi['001'] == 1)
  assert(mode_atoi['007'] == 7)
  assert(mode_atoi['070'] == 7 * 8)
  assert(mode_atoi['700'] == 7 * 64)
  assert(mode_atoi['777'] == 511)

  assert(mode_atoi['--------x'] == 1)
  assert(mode_atoi['-------w-'] == 2)
  assert(mode_atoi['------r--'] == 4)
  assert(mode_atoi['-----x---'] == 8)
  assert(mode_atoi['----w----'] == 16)
  assert(mode_atoi['---r-----'] == 32)
  assert(mode_atoi['--x------'] == 64)
  assert(mode_atoi['-w-------'] == 128)
  assert(mode_atoi['r--------'] == 256)
  assert(mode_atoi['rwxrwxrwx'] == 511)

  assert(mode_atoi[1] == 1)
  assert(mode_atoi[511] == 511)

  do
    local ok, err = pcall(function() return mode_atoi[true] end)
    assert(not ok)
    assert(err:find('unexpected mode type: boolean'))
  end
end

--------------------------------------------------------------------------------
-- File
--------------------------------------------------------------------------------

local File = class(function(descriptor)
  return { descriptor = descriptor }
end)

function File:read()
  return uv.fs():read(self.descriptor)
end

function File:close()
  return uv.fs():close(self.descriptor)
end

function File:write(buffer)
  return uv.fs():write(self.descriptor, buffer)
end

function File:chmod(mode)
  local mode = mode_atoi[mode or '700']
  return uv.fs():fchmod(self.descriptor, mode)
end

function File:chown(uid, gid)
  return uv.fs():fchown(self.descriptor, uid, gid)
end

function File:fsync()
  return uv.fs():fsync(self.descriptor)
end

--------------------------------------------------------------------------------
-- fs
--------------------------------------------------------------------------------

local fs = {}

function fs.open(path, flags, mode)
  local flags = flags_atoi[flags or 'r']
  local mode = mode_atoi[mode or '700']
  local mask = ffi.C.umask(0)
  local descriptor = uv.fs():open(path, flags, mode)
  ffi.C.umask(mask)
  return File(descriptor)
end

function fs.unlink(path)
  return uv.fs():unlink(path)
end

function fs.mkdir(path, mode)
  local mode = mode_atoi[mode or '700']
  return uv.fs():mkdir(path, mode)
end

function fs.rmdir(path)
  return uv.fs():rmdir(path)
end

function fs.chmod(path, mode)
  local mode = mode_atoi[mode or '700']
  return uv.fs():chmod(path, mode)
end

function fs.chown(path, uid, gid)
  return uv.fs():chown(path, uid, gid)
end

function fs.stat(path)
  return uv.fs():stat(path)
end

function fs.fstat(path)
  return uv.fs():fstat(path)
end

function fs.lstat(path)
  return uv.fs():lstat(path)
end

function fs.rename(path, new_path)
  return uv.fs():rename(path, new_path)
end

function fs.link(path, new_path)
  return uv.fs():link(path, new_path)
end

function fs.symlink(path, new_path)
  return uv.fs():symlink(path, new_path, 0)
end

function fs.readlink(path)
  return uv.fs():readlink(path)
end

function fs.tmpname()
  return os.tmpname()
end

return fs
