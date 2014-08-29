require 'uv/util/strict'
local uv = require 'uv'
local process = require 'uv.process'
local timer = require 'uv.timer'
local expect = require 'uv/util/expect'

uv.run(function()
  local count = 0
  process.on('hup', function()
    count = count + 1
  end)
  process.kill(process.pid(), 'hup')
  process.kill(process.pid(), 'hup')
  process.kill(process.pid(), 'hup')
  timer.sleep(1)
  expect.equal(count, 3)
  uv.stop()
end)

do
  assert(process.path():find('luajit'))
end
