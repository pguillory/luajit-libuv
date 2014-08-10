require 'uv/cdef'
local ffi = require 'ffi'
local async = require 'async'
local ctype = require 'ctype'
local libuv = require 'uv/libuv'

--------------------------------------------------------------------------------
-- uv_timer_t
--------------------------------------------------------------------------------

local uv_timer_t = ctype('uv_timer_t')

function uv_timer_t:start(callback, timeout, repeat_time)
  return self.loop:assert(libuv.uv_timer_start(self, callback, timeout or 0, repeat_time or 0))
end

return uv_timer_t
