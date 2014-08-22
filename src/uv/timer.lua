local join = require 'uv/join'
local uv_timer_t = require 'uv/uv_timer_t'

local timer = {}

function timer.set(timeout, callback)
  join(coroutine.create(function()
    local timer = uv_timer_t()
    timer:sleep(timeout)
    timer:free()
    callback()
  end))
end

function timer.every(timeout, callback)
  join(coroutine.create(function()
    local timer = uv_timer_t()
    timer:every(timeout, callback)
    timer:free()
  end))
end

function timer.sleep(timeout)
  local timer = uv_timer_t()
  timer:sleep(timeout)
  timer:free()
end

return timer
