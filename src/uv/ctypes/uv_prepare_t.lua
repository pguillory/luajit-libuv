local ffi = require 'ffi'
local async = require 'uv/util/async'
local ctype = require 'uv/util/ctype'
local libuv = require 'uv/libuv'
local libuv2 = require 'uv/libuv2'
local libc = require 'uv/libc'

local uv_prepare_t = ctype('uv_prepare_t', function(loop)
  loop = loop or libuv.uv_default_loop()
  local self = ffi.cast('uv_prepare_t*', libc.malloc(ffi.sizeof('uv_prepare_t')))
  loop:assert(libuv.uv_prepare_init(loop, self))
  return self
end)

function uv_prepare_t:start(callback)
  self.loop:assert(libuv.uv_prepare_start(self, async.uv_prepare_cb))
  while true do
    async.yield(self)
    callback()
  end
end

return uv_prepare_t
