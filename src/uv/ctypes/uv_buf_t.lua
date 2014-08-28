local ffi = require 'ffi'
local ctype = require 'uv/util/ctype'
local libuv = require 'uv/libuv'
local libuv2 = require 'uv/libuv2'
local libc = require 'uv/libc'

--------------------------------------------------------------------------------
-- uv_buf_t
--------------------------------------------------------------------------------

local uv_buf_t = ctype('uv_buf_t', function(base, len)
  local self = ffi.cast('uv_buf_t*', libc.malloc(ffi.sizeof('uv_buf_t')))
  self.len = len or 65536
  self.base = libc.malloc(self.len)
  if base then
    assert(#base <= self.len)
    ffi.copy(self.base, base, #base)
  end
  return self
end)

function uv_buf_t:free()
  libc.free(self.base)
  libc.free(self)
end

return uv_buf_t
