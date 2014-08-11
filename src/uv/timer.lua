local uv = require 'uv'

local timer = {}

function timer.set(callback, delay, repeat_delay)
  local t = uv.timer()
  t:start(callback, delay, repeat_delay)
  return t
end

return timer
