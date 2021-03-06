require 'uv/util/strict'
local loop = require 'uv.loop'
local timer = require 'uv.timer'
local expect = require 'uv/util/expect'

for i = 1, 1000 do
  loop.run(function()
  end)
end

assert(loop.alive() == false)
loop.run(function()
  assert(loop.alive() == false)
  timer.set(0, function()
    assert(loop.alive() == false)
  end)
  assert(loop.alive() == true)
end)
assert(loop.alive() == false)

do
  local buffer = {}
  table.insert(buffer, '1')
  loop.run(function()
    table.insert(buffer, '2')
    timer.set(0, function()
      table.insert(buffer, '4')
    end)
    table.insert(buffer, '3')
  end)
  table.insert(buffer, '5')
  expect.equal(table.concat(buffer), '12345')
end

loop.run(function()
  local buffer = {}
  loop.yield(function()
    table.insert(buffer, 'yield')
  end)
  loop.resume(function()
    table.insert(buffer, 'resume')
  end)
  table.insert(buffer, 'before')
  timer.sleep(1)
  table.insert(buffer, 'after')
  expect.equal(table.concat(buffer, ' '), 'before yield resume after')
  loop.stop()
end)

loop.run(function()
  local buffer = {}
  local count = 0
  loop.idle(function()
    count = count + 1
    if not buffer[2] then
      buffer[2] = 'idle'
    end
  end)
  table.insert(buffer, 'before')
  timer.sleep(2)
  table.insert(buffer, 'after')
  expect.equal(table.concat(buffer, ' '), 'before idle after')
  assert(count > 0)
  loop.stop()
end)
