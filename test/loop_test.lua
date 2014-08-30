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
