require 'strict'
local uv = require 'uv'

for i = 1, 1000 do
  uv.run(function()
  end)
end

uv.run(function()
  local server = uv.tcp()
  server:bind('127.0.0.1', 7000)
  server:listen(function(stream)
    assert(stream:read() == 'foo')
    stream:write('bar')
    stream:close()
  end)

  local client = uv.tcp()
  local stream = client:connect('127.0.0.1', 7000).handle
  stream:write('foo')
  assert(stream:read() == 'bar')
  stream:close()

  server:close()
end)

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
