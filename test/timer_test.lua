require 'strict'
local uv = require 'uv'

local s = ''
uv.run(function()
  local t5 = uv.timer(); t5:start(function() s = s .. 'e' end, 5)
  local t3 = uv.timer(); t3:start(function() s = s .. 'c' end, 3)
  local t1 = uv.timer(); t1:start(function() s = s .. 'a' end, 1)
  local t2 = uv.timer(); t2:start(function() s = s .. 'b' end, 2)
  local t4 = uv.timer(); t4:start(function() s = s .. 'd' end, 4)
  local t6 = uv.timer(); t6:start(function() s = s .. 'f' end, 6)
  t4:stop()
end)
assert(s == 'abcef')

local s = ''
uv.run(function()
  local t = uv.timer()
  assert(t:get_repeat() == 0)
  t:start(function(self)
    s = s .. 'a'
    if #s >= 5 then self:stop() end
  end, 0, 1)
  assert(t:get_repeat() == 1)
end)
assert(s == 'aaaaa')
