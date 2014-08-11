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
