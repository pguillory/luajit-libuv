require 'uv/cdef'
local ffi = require 'ffi'
local async = require 'async'
local ctype = require 'ctype'
local libuv = require 'uv/libuv'

--------------------------------------------------------------------------------
-- uv_timer_t
--------------------------------------------------------------------------------

local uv_timer_t = ctype('uv_timer_t')

uv_timer_t.start = async.server('uv_timer_cb', function(yield, callback, self, on_timeout, timeout, repeat_time)
  self.loop:assert(libuv.uv_timer_start(self, callback, timeout or 0, repeat_time or 0))
  yield(self, on_timeout)
end)

function uv_timer_t:stop()
  self.loop:assert(libuv.uv_timer_stop(self))
end

function uv_timer_t:again()
  self.loop:assert(libuv.uv_timer_again(self))
end

function uv_timer_t:set_repeat(repeat_time)
  libuv.uv_timer_set_repeat(self, repeat_time)
end

function uv_timer_t:get_repeat()
  return libuv.uv_timer_get_repeat(self)
end

return uv_timer_t
