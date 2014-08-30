require 'uv/util/strict'
local loop = require 'uv.loop'
local parallel = require 'uv.parallel'
local timer = require 'uv.timer'

do
  local log = {}
  loop.run(function()
    parallel.range(3, function(i)
      table.insert(log, i)
      timer.sleep(1)
      table.insert(log, i)
    end)
  end)
  assert(table.concat(log) == '123123')
end

do
  local log = {}
  parallel.range(3, function(i)
    table.insert(log, i)
    timer.sleep(1)
    table.insert(log, i)
  end)
  assert(table.concat(log) == '123123')
end

do
  local inputs = { 'a', 'b', 'c' }
  local log = {}
  local outputs = {}

  loop.run(function()
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
