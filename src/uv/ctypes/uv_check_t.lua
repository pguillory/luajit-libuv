local ffi = require 'ffi'
local async = require 'uv/util/async'
local ctype = require 'uv/util/ctype'
local libuv = require 'uv/libuv'
local libuv2 = require 'uv/libuv2'
local libc = require 'uv/libc'
local verify = require 'uv/util/verify'

local uv_check_t = ctype('uv_check_t', function(loop)
  loop = loop or libuv.uv_default_loop()
  local self = ffi.cast('uv_check_t*', libc.malloc(ffi.sizeof('uv_check_t')))
  verify(libuv.uv_check_init(loop, self))
  return self
end)

function uv_check_t:start(callback)
  verify(libuv.uv_check_start(self, async.uv_check_cb))
  while true do
    async.yield(self)
    callback()
  end
end

return uv_check_t
