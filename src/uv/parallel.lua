local join = require 'uv/join'
local timer = require 'uv.timer'
local libuv = require 'uv/libuv'

local parallel = {}

function parallel.map(inputs, callback)
  local thread = coroutine.running()
  local busy = #inputs
  local outputs = {}

  for i, input in ipairs(inputs) do
    timer.set(0, function()
      outputs[i] = callback(input)
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

  return outputs
end

return parallel
