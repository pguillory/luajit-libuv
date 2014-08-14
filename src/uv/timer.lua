local uv = require 'uv'
local join = require 'uv/join'

local timer = {}

function timer.set(timeout, callback)
  join(coroutine.create(function()
    uv.timer():sleep(timeout)
    callback()
  end))
end

function timer.every(timeout, callback)
  uv.timer():every(timeout, callback)
end

function timer.sleep(timeout)
  uv.timer():sleep(timeout)
end

return timer
