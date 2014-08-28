local ffi = require 'ffi'
local libuv = require 'uv/libuv'

local errno_mt = {}

local errno = setmetatable({}, {
  __call = function(self, n)
    return ffi.string(libuv.uv_err_name(n)) .. ': ' .. ffi.string(libuv.uv_strerror(n))
  end,
  __index = function(self, n)
    self[n] = self(n)
    return self[n]
  end,
})

assert(errno[-1] == 'EPERM: operation not permitted')
assert(errno[-2] == 'ENOENT: no such file or directory')

return errno
