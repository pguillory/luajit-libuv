local uv = require 'uv'
local parallel = require 'uv.parallel'
local timer = require 'uv.timer'

do
  local inputs = { 'a', 'b', 'c' }
  local log = {}
  local outputs = {}

  uv.run(function()
    outputs = parallel.map(inputs, function(input)
      table.insert(log, input)
      timer.sleep(1)
      local output = string.upper(input)
      table.insert(log, output)
      return output
    end)
    assert(table.concat(outputs) == 'ABC')
  end)

  assert(table.concat(log) == 'abcABC')
end

do
  local inputs = { 'a', 'b', 'c' }
  local log = {}
  local outputs = {}

  outputs = parallel.map(inputs, function(input)
    table.insert(log, input)
    timer.sleep(1)
    local output = string.upper(input)
    table.insert(log, output)
    return output
  end)

  assert(table.concat(outputs) == 'ABC')
  assert(table.concat(log) == 'abcABC')
end
