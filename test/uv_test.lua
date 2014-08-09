require 'strict'
local uv = require 'uv'

local ffi = require 'ffi'
ffi.cdef [[
  mode_t umask(mode_t mask);
  uid_t getuid(void);
]]
ffi.C.umask(0)
local uid = ffi.C.getuid()

do
  local dir = os.tmpname()
  -- print('ls -alF ' .. dir)
  os.remove(dir)

  uv.run(function()
    local fs = uv.fs()
    local filename = dir .. '/777.txt'
    
    fs:mkdir(dir)

    local file = fs:open(filename, 'w', '777')
    fs:write(file, 'hello!')
    fs:close(file)

    local stat = fs:stat(filename)
    assert(stat:uid() == uid)
    assert(stat:access() == 511) -- octal('777')
    assert(stat:size() == 6)
    assert(stat:is_dir() == false)
    assert(stat:is_fifo() == false)

    fs:unlink(filename)
    fs:rmdir(dir)
  end)
end

print('All tests passing')
