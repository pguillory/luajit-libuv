require 'uv/cdef'
local ffi = require 'ffi'
local async = require 'uv/async'
local async2 = require 'uv/async2'
local ctype = require 'uv/ctype'
local libuv = require 'uv/libuv'

--------------------------------------------------------------------------------
-- uv_timer_t
--------------------------------------------------------------------------------

local uv_timer_t = ctype('uv_timer_t')

function uv_timer_t:every(timeout, callback)
  self.loop:assert(libuv.uv_timer_start(self, async2.uv_timer_cb, timeout, timeout))
  while true do
    callback(self, async2.yield(self))
  end
end

function uv_timer_t:sleep(timeout)
  self.loop:assert(libuv.uv_timer_start(self, async2.uv_timer_cb, timeout, 0))
  async2.yield(self)
end

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
