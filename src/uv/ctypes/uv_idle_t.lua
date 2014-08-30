local ffi = require 'ffi'
local async = require 'uv/util/async'
local ctype = require 'uv/util/ctype'
local libuv = require 'uv/libuv'
local libuv2 = require 'uv/libuv2'
local libc = require 'uv/libc'
local verify = require 'uv/util/verify'

local uv_idle_t = ctype('uv_idle_t', function(loop)
  local self = ffi.cast('uv_idle_t*', libc.malloc(ffi.sizeof('uv_idle_t')))
  verify(libuv.uv_idle_init(loop or libuv.uv_default_loop(), self))
  return self
end)

function uv_idle_t:start(callback)
  verify(libuv.uv_idle_start(self, async.uv_idle_cb))
  while true do
    async.yield(self)
    callback()
  end
end

return uv_idle_t
