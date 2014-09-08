API Reference - uv.tcp
=======================

The `tcp` module provides both a client and a server.

### tcp.listen(host, port)

Start listening for TCP connections. Returns a server object. Call
`server:accept()` to accept a new connection and `server:close()` to stop
listening.

```lua
local server = tcp.listen('127.0.0.1', 7000)
while true do
  local socket = server:accept()
  while true do
    local data = socket:read()
    if data:find('quit') then
      break
    end
    socket:write(data)
  end
  socket:close()
end
```

### tcp.connect(host, port)

Connect to a TCP server. Returns a connection with `read`, `write`, and
`close` methods.

```lua
local socket = tcp.connect('127.0.0.1', 7000)
socket:write('ping')
local data = socket:read()
socket:write('quit')
socket:close()
```
