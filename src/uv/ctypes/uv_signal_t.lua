local ffi = require 'ffi'
local async = require 'uv/util/async'
local ctype = require 'uv/util/ctype'
local libuv = require 'uv/libuv'
local libuv2 = require 'uv/libuv2'
local libc = require 'uv/libc'

--------------------------------------------------------------------------------
-- uv_signal_t
--------------------------------------------------------------------------------

local uv_signal_t = ctype('uv_signal_t', function(loop)
  loop = loop or libuv.uv_default_loop()
  local self = ffi.cast('uv_signal_t*', libc.malloc(ffi.sizeof('uv_signal_t')))
  loop:assert(libuv.uv_signal_init(loop, self))
  return self
end)

function uv_signal_t:start(signum, callback)
  self.loop:assert(libuv.uv_signal_start(self, async.uv_signal_cb, signum))
  while true do
    local signum = async.yield(self)
    callback()
  end
end

function uv_signal_t:stop()
  loop:assert(libuv.uv_signal_stop(self))
end

function uv_signal_t:free()
  libc.free(self)
end

return uv_signal_t
