API Reference - uv.tcp
=======================

The `tcp` module provides both a client and a server.

### tcp.listen(host, port, on_connect)

Listen for TCP connections. For each connection, `on_connect` will be passed a
stream with `read`, `write`, and `close` methods.

```lua
tcp.listen('127.0.0.1', 7000, function(socket)
  while true do
    local data = socket:read()
    socket:write(data)
  end
end)
```

### tcp.connect(host, port)

Connect to a TCP server. Returns a stream with `read`, `write`, and `close`
methods.

```lua
local socket = tcp.connect('127.0.0.1', 7000)
socket:write('ping')
local data = socket:read()
socket:close()
```
