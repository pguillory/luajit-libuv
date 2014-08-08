require 'strict'
local ffi = require 'ffi'
local uv = require 'uv'

uv.run(function()
  local server = uv.tcp()
  server:bind('0.0.0.0', 7000)
  server:listen(function(client)
    print('connected: ', client)
    local s = ''
    repeat
      -- print(s)
      client:write(s)
      s = client:read()
    until s:sub(1, 4) == 'quit'
    client:close()
  end)
end)
