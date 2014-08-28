local ffi = require 'ffi'
local ctype = require 'uv/util/ctype'
local libuv = require 'uv/libuv'
local libuv2 = require 'uv/libuv2'
local libc = require 'uv/libc'

--------------------------------------------------------------------------------
-- uv_write_t
--------------------------------------------------------------------------------

local uv_write_t = ctype('uv_write_t', function()
  local self = ffi.cast('uv_write_t*', libc.malloc(ffi.sizeof('uv_write_t')))
  return self
end)

function uv_write_t:free()
  libc.free(self)
end

return uv_write_t
