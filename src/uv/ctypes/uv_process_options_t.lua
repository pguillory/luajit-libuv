local ffi = require 'ffi'
local async = require 'uv/util/async'
local ctype = require 'uv/util/ctype'
local libuv = require 'uv/libuv'
local libuv2 = require 'uv/libuv2'
local libc = require 'uv/libc'

local uv_process_options_t = ctype('uv_process_options_t', function(loop)
  local self = ffi.cast('uv_process_options_t*', libc.malloc(ffi.sizeof('uv_process_options_t')))
  ffi.fill(self, ffi.sizeof('uv_process_options_t'), 0)
  return self
end)

function uv_process_options_t:free()
  libc.free(self)
end

return uv_process_options_t
