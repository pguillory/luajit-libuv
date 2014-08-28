local ffi = require 'ffi'
local ctype = require 'uv/util/ctype'
local libuv = require 'uv/libuv'
local libuv2 = require 'uv/libuv2'
local libc = require 'uv/libc'

--------------------------------------------------------------------------------
-- uv_connect_t
--------------------------------------------------------------------------------

local uv_connect_t = ctype('uv_connect_t', function()
  local self = ffi.cast('uv_connect_t*', libc.malloc(ffi.sizeof('uv_connect_t')))
  return self
end)

function uv_connect_t:free()
  libc.free(self)
end

return uv_connect_t
