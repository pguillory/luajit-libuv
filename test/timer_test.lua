local uv = require 'uv'
local timer = require 'uv.timer'

local s = ''
uv.run(function()
  timer.set(function() s = s .. 'e' end, 5)
  timer.set(function() s = s .. 'c' end, 3)
  timer.set(function() s = s .. 'a' end, 1)
  timer.set(function() s = s .. 'b' end, 2)
  timer.set(function() s = s .. 'd' end, 4)
  timer.set(function() s = s .. 'f' end, 6)
end)
assert(s == 'abcdef', s)

local s = ''
uv.run(function()
  timer.set(function(self)
    s = s .. 'a'
    if #s >= 5 then self:stop() end
  end, 0, 1)
end)
assert(s == 'aaaaa')
