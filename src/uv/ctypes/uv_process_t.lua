local ffi = require 'ffi'
local async = require 'uv/util/async'
local ctype = require 'uv/util/ctype'
local libuv = require 'uv/libuv'
local libuv2 = require 'uv/libuv2'
local libc = require 'uv/libc'
local verify = require 'uv/util/verify'

local uv_process_t = ctype('uv_process_t', function(loop)
  local self = ffi.cast('uv_process_t*', libc.malloc(ffi.sizeof('uv_process_t')))
  self.loop = loop or libuv.uv_default_loop()
  return self
end)

function uv_process_t:spawn(options)
  verify(libuv.uv_spawn(self.loop, self, options))
  local exit_status, term_signal = async.yield(self)
  verify(exit_status)
  return term_signal
end

function uv_process_t:kill(signum)
  verify(libuv.uv_process_kill(self, signum))
end

return uv_process_t
