local uv = require 'uv'
local http = require 'uv.http'

uv.run(function()
  local server = http.server(uv.loop)
  server:bind('127.0.0.1', 7000)
  server:listen(function(request)
    return 200, {}, 'hello world'
  end)

  local client = uv.tcp()
  local stream = client:connect('127.0.0.1', 7000).handle
  stream:write('GET / HTTP/1.1\n\n')
  local response = stream:read()
  -- print(response)
  assert(response:find('HTTP/1.1 200 OK'))
  assert(response:find('hello world'))
  stream:close()

  server:close()
end)
