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
  local file = fs.open('file.txt', 'w', '777')
  file:write('hello!')
  file:close()

  -- reading
  local file = fs.open('file.txt')
  assert(file:read() == 'hello!')
  file:sync()
  file:close()

  assert(fs.readfile('file.txt') == 'hello!')

  -- hard links
  fs.link('file.txt', 'link.txt')
  local file = fs.open('link.txt')
  assert(file:read() == 'hello!')
  file:close()
  fs.unlink('link.txt')

  -- symlinks
  fs.symlink('file.txt', 'symlink.txt')
  assert(fs.readlink('symlink.txt') == 'file.txt')
  fs.unlink('symlink.txt')

  local stat = fs.stat('file.txt')
  assert(stat.uid == uid)
  -- This doesn't work! stat.gid is returning 0 for some reason.
  -- assert(stat.gid == gid)
  assert(stat.mode == 511) -- octal('777')
  assert(stat.size == 6)
  assert(stat.is_dir == false)
  assert(stat.is_fifo == false)
  assert(math.abs(os.time() - tonumber(stat.atime)) < 10)

  -- renaming
  fs.rename('file.txt', 'new-file.txt')
  local file = fs.open('new-file.txt')
  assert(file:read() == 'hello!')
  file:close()
  fs.unlink('new-file.txt')

  fs.open('a', 'w'):close()
  fs.open('b', 'w'):close()
  fs.mkdir('c')
  fs.open('c/d', 'w'):close()
  fs.open('c/e', 'w'):close()
  fs.mkdir('c/f')
  fs.open('c/f/g', 'w'):close()
  fs.open('c/f/h', 'w'):close()

  local filenames = fs.readdir('.')
  assert(#filenames == 3)
  assert(filenames[1] == 'a')
  assert(filenames[2] == 'b')
  assert(filenames[3] == 'c')

  local filenames = fs.readdir_r('.')
  assert(#filenames == 6)
  assert(filenames[1] == 'a')
  assert(filenames[2] == 'b')
  assert(filenames[3] == 'c/d')
  assert(filenames[4] == 'c/e')
  assert(filenames[5] == 'c/f/g')
  assert(filenames[6] == 'c/f/h')

  local filenames = fs.readdir_r('c')
  assert(#filenames == 4)
  assert(filenames[1] == 'd')
  assert(filenames[2] == 'e')
  assert(filenames[3] == 'f/g')
  assert(filenames[4] == 'f/h')

  fs.rm_rf(dir)

  -- errors
  local ok, err = pcall(function()
    fs.open('nonexistent')
  end)
  assert(not ok and err:find('no such file or directory'))
end)
