local uv = require 'uv'

uv.run(function()
  local server = uv.tcp()
  server:bind('0.0.0.0', 7000)
  server:listen(function(client)
    local s = 'Type "quit" to disconnect, or anything else to get an echo.\n'
    repeat
      client:write(s)
      s = client:read()
    until s:find('quit')
    client:close()
  end)
end)
