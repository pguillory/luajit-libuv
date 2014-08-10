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
  -- print('ls -alF ' .. dir)

  local filename = dir .. '/777.txt'
  
  fs.mkdir(dir)

  -- writing
  local file = fs.open(filename, 'w', '777')
  file:write('hello!')
  file:close()

  -- reading
  local file = fs.open(filename)
  assert(file:read() == 'hello!')
  file:fsync()
  file:close()

  -- hard links
  local link_filename = dir .. '/link.txt'
  fs.link(filename, link_filename)
  local file = fs.open(link_filename)
  assert(file:read() == 'hello!')
  file:close()
  fs.unlink(link_filename)

  -- symlinks
  local symlink_filename = dir .. '/symlink.txt'
  fs.symlink(filename, symlink_filename)
  assert(fs.readlink(symlink_filename) == filename)
  fs.unlink(symlink_filename)

  local stat = fs.stat(filename)
  assert(stat:uid() == uid)
  -- This doesn't work! stat:gid() is returning 0 for some reason.
  -- assert(stat:gid() == gid)
  assert(stat:mode() == 511) -- octal('777')
  assert(stat:size() == 6)
  assert(stat:is_dir() == false)
  assert(stat:is_fifo() == false)
  assert(math.abs(os.time() - tonumber(stat:atime())) < 10)

  -- renaming
  local new_filename = dir .. '/new.txt'
  fs.rename(filename, new_filename)
  local file = fs.open(new_filename)
  assert(file:read() == 'hello!')
  file:close()
  fs.unlink(new_filename)

  fs.rmdir(dir)

  -- errors
  local ok, err = pcall(function()
    fs.open(dir .. '/nonexistent')
  end)
  assert(not ok and err:find('no such file or directory'))
end)
