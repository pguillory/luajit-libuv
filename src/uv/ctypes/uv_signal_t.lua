local ffi = require 'ffi'
local async = require 'uv/util/async'
local ctype = require 'uv/util/ctype'
local libuv = require 'uv/libuv'
local libuv2 = require 'uv/libuv2'
local libc = require 'uv/libc'
local verify = require 'uv/util/verify'

--------------------------------------------------------------------------------
-- uv_signal_t
--------------------------------------------------------------------------------

local uv_signal_t = ctype('uv_signal_t', function(loop)
  local self = ffi.cast('uv_signal_t*', libc.malloc(ffi.sizeof('uv_signal_t')))
  verify(libuv.uv_signal_init(loop or libuv.uv_default_loop(), self))
  return self
end)

function uv_signal_t:start(signum, callback)
  verify(libuv.uv_signal_start(self, async.uv_signal_cb, signum))
  while true do
    local signum = async.yield(self)
    callback()
  end
end

function uv_signal_t:stop()
  verify(libuv.uv_signal_stop(self))
end

function uv_signal_t:free()
  libc.free(self)
end

return uv_signal_t
