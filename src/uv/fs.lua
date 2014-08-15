local class = require 'uv/class'
local ffi = require 'ffi'
local libuv = require 'uv/libuv'
local uv = require 'uv'
local uv_fs_t = require 'uv/uv_fs_t'

ffi.cdef [[
  mode_t umask(mode_t mask);
]]
-- ffi.C.umask(0)


--------------------------------------------------------------------------------
-- octal
--------------------------------------------------------------------------------

local function octal(s)
  local i = 0
  for c in s:gmatch('.') do
    i = i * 8 + tonumber(c)
  end
  return i
end

do
  assert(octal('0') == 0)
  assert(octal('1') == 1)
  assert(octal('10') == 8)
  assert(octal('11') == 9)
  assert(octal('100') == 64)
  assert(octal('101') == 65)
end

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
      i = octal(s)
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
-- Stat
--------------------------------------------------------------------------------

local S_IFMT    = octal('0170000')  -- type of file mask
local S_IFIFO   = octal('0010000')  -- named pipe (fifo)
local S_IFCHR   = octal('0020000')  -- character special
local S_IFDIR   = octal('0040000')  -- directory
local S_IFBLK   = octal('0060000')  -- block special
local S_IFREG   = octal('0100000')  -- regular
local S_IFLNK   = octal('0120000')  -- symbolic link
local S_IFSOCK  = octal('0140000')  -- socket

local Stat = function(stat)
  return {
    uid           = stat.st_uid,
    gid           = stat.st_gid,
    size          = stat.st_size,
    mode          = bit.band(tonumber(stat.st_mode), bit.bnot(S_IFMT)),
    is_dir        = bit.band(tonumber(stat.st_mode), S_IFDIR) > 0,
    is_fifo       = bit.band(tonumber(stat.st_mode), S_IFIFO) > 0,
    atime         = stat.st_atim.tv_sec,
    atimensec     = stat.st_atim.tv_nsec,
    mtime         = stat.st_mtim.tv_sec,
    mtimensec     = stat.st_mtim.tv_nsec,
    ctime         = stat.st_ctim.tv_sec,
    ctimensec     = stat.st_ctim.tv_nsec,
    birthtime     = stat.st_birthtim.tv_sec,
    birthtimensec = stat.st_birthtim.tv_nsec,
  }
end

--------------------------------------------------------------------------------
-- File
--------------------------------------------------------------------------------

local File = class(function(descriptor)
  return { descriptor = descriptor }
end)

function File:read()
  return uv_fs_t():read(self.descriptor)
end

function File:close()
  return uv_fs_t():close(self.descriptor)
end

function File:write(buffer)
  return uv_fs_t():write(self.descriptor, buffer)
end

function File:chmod(mode)
  local mode = mode_atoi[mode or '700']
  return uv_fs_t():fchmod(self.descriptor, mode)
end

function File:chown(uid, gid)
  return uv_fs_t():fchown(self.descriptor, uid, gid)
end

function File:sync()
  return uv_fs_t():fsync(self.descriptor)
end

function File.stat()
  return Stat(uv_fs_t():fstat(self.descriptor))
end

--------------------------------------------------------------------------------
-- fs
--------------------------------------------------------------------------------

local fs = {}

function fs.open(path, flags, mode)
  local flags = flags_atoi[flags or 'r']
  local mode = mode_atoi[mode or '700']
  local mask = ffi.C.umask(0)
  local descriptor = uv_fs_t():open(path, flags, mode)
  ffi.C.umask(mask)
  return File(descriptor)
end

function fs.unlink(path)
  return uv_fs_t():unlink(path)
end

function fs.mkdir(path, mode)
  local mode = mode_atoi[mode or '700']
  return uv_fs_t():mkdir(path, mode)
end

function fs.rmdir(path)
  return uv_fs_t():rmdir(path)
end

function fs.chmod(path, mode)
  local mode = mode_atoi[mode or '700']
  return uv_fs_t():chmod(path, mode)
end

function fs.chown(path, uid, gid)
  return uv_fs_t():chown(path, uid, gid)
end

function fs.stat(path)
  return Stat(uv_fs_t():stat(path))
end

function fs.lstat(path)
  return uv_fs_t():lstat(path)
end

function fs.rename(path, new_path)
  return uv_fs_t():rename(path, new_path)
end

function fs.link(path, new_path)
  return uv_fs_t():link(path, new_path)
end

function fs.symlink(path, new_path)
  return uv_fs_t():symlink(path, new_path, 0)
end

function fs.readlink(path)
  return uv_fs_t():readlink(path)
end

function fs.readfile(path)
  local file = fs.open(path)
  local buffer = {}
  repeat
    local chunk = file:read()
    table.insert(buffer, chunk)
  until chunk == ''
  file:close()
  return table.concat(buffer)
end

function fs.tmpname()
  return os.tmpname()
end

function fs.cwd()
  local buf = ffi.new('char[?]', 4096)
  local len = ffi.new('uint64_t[1]')
  len[0] = 4096
  assert(0 == libuv.uv_cwd(buf, len))
  return ffi.string(buf)
end

function fs.chdir(dir)
  assert(0 == libuv.uv_chdir(dir))
end

return fs
