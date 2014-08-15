require 'uv/cdef'
local ffi = require 'ffi'
local ctype = require 'uv/ctype'
local libuv = require 'uv/libuv'
local libuv2 = require 'uv/libuv2'

--------------------------------------------------------------------------------
-- uv_buf_t
--------------------------------------------------------------------------------

local uv_buf_t = ctype('uv_buf_t', function(base, len)
  local self = ffi.cast('uv_buf_t*', ffi.C.malloc(ffi.sizeof('uv_buf_t')))
  self.len = len or 65536
  self.base = ffi.C.malloc(self.len)
  if base then
    assert(#base <= self.len)
    ffi.copy(self.base, base, #base)
  end
  return self
end)

function uv_buf_t:free()
  ffi.C.free(self.base)
  ffi.C.free(self)
end

return uv_buf_t
