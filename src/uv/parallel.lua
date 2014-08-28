require 'uv/ctypes/init'
local join = require 'uv/util/join'
local timer = require 'uv.timer'
local libuv = require 'uv/libuv'

local parallel = {}

function parallel.map(inputs, callback)
  local outputs = {}

  parallel.range(#inputs, function(i)
    outputs[i] = callback(inputs[i])
  end)

  return outputs
end

function parallel.range(n, callback)
  local thread = coroutine.running()
  local busy = n

  for i = 1, n do
    timer.set(0, function()
      callback(i)
      busy = busy - 1
      if busy == 0 then
        join(thread)
      end
    end)
  end

  if thread then
    coroutine.yield()
  else
    busy = 0
    libuv.uv_default_loop():run()
  end
end

return parallel
