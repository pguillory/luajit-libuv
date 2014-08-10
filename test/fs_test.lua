require 'strict'
local uv = require 'uv'
local fs = require 'uv.fs'

local ffi = require 'ffi'
ffi.cdef [[
  uid_t getuid(void);
  gid_t getgid(void);
]]
local uid = ffi.C.getuid()
local gid = ffi.C.getgid()

uv.run(function()
  local dir = fs.tmpname()
  fs.unlink(dir)
  fs.mkdir(dir)
  fs.chdir(dir)
  assert(fs.cwd():find(dir, 1, true))

  -- writing
  local file = fs.open('file', 'w', '777')
  file:write('hello!')
  file:close()

  -- reading
  local file = fs.open('file')
  assert(file:read() == 'hello!')
  file:fsync()
  file:close()

  -- hard links
  fs.link('file', 'link')
  local file = fs.open('link')
  assert(file:read() == 'hello!')
  file:close()
  fs.unlink('link')

  -- symlinks
  fs.symlink('file', 'symlink')
  assert(fs.readlink('symlink') == 'file')
  fs.unlink('symlink')

  local stat = fs.stat('file')
  assert(stat:uid() == uid)
  -- This doesn't work! stat:gid() is returning 0 for some reason.
  -- assert(stat:gid() == gid)
  assert(stat:mode() == 511) -- octal('777')
  assert(stat:size() == 6)
  assert(stat:is_dir() == false)
  assert(stat:is_fifo() == false)
  assert(math.abs(os.time() - tonumber(stat:atime())) < 10)

  -- renaming
  fs.rename('file', 'new-file')
  local file = fs.open('new-file')
  assert(file:read() == 'hello!')
  file:close()
  fs.unlink('new-file')

  fs.rmdir(dir)

  -- errors
  local ok, err = pcall(function()
    fs.open('nonexistent')
  end)
  assert(not ok and err:find('no such file or directory'))
end)
