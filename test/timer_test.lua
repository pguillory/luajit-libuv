require 'uv/util/strict'
local loop = require 'uv.loop'
local timer = require 'uv.timer'

do
  local s = ''
  timer.set(5, function() s = s .. 'e' end)
  timer.set(3, function() s = s .. 'c' end)
  timer.set(1, function() s = s .. 'a' end)
  timer.set(2, function() s = s .. 'b' end)
  timer.set(4, function() s = s .. 'd' end)
  timer.set(6, function() s = s .. 'f' end)
  loop.run()
  assert(s == 'abcdef')
end

local s = ''
loop.run(function()
  timer.set(5, function() s = s .. 'e' end)
  timer.set(3, function() s = s .. 'c' end)
  timer.set(1, function() s = s .. 'a' end)
  timer.set(2, function() s = s .. 'b' end)
  timer.set(4, function() s = s .. 'd' end)
  timer.set(6, function() s = s .. 'f' end)
end)
assert(s == 'abcdef')

do
  local s = ''
  timer.every(1, function(self)
    s = s .. 'a'
    if #s >= 5 then self:stop() end
  end)
  loop.run()
  assert(s == 'aaaaa')
end

local s = ''
loop.run(function()
  timer.every(1, function(self)
    s = s .. 'a'
    if #s >= 5 then self:stop() end
  end)
end)
assert(s == 'aaaaa')
