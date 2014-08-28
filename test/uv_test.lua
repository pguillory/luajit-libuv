require 'uv/util/strict'
local uv = require 'uv'
local uv_tcp_t = require 'uv/ctypes/uv_tcp_t'
local uv_getaddrinfo_t = require 'uv/ctypes/uv_getaddrinfo_t'

for i = 1, 1000 do
  uv.run(function()
  end)
end

uv.run(function()
  local server = uv_tcp_t()
  server:bind('127.0.0.1', 7000)
  server:listen(function(stream)
    assert(stream:read() == 'foo')
    stream:write('bar')
  end)

  local client = uv_tcp_t()
  local stream = client:connect('127.0.0.1', 7000)
  stream:write('foo')
  assert(stream:read() == 'bar')
  stream:close()

  server:close()
end)

uv.run(function()
  local getaddrinfo = uv_getaddrinfo_t()

  local addrs = getaddrinfo:getaddrinfo('123.123.123.123', 'https')
  assert(#addrs > 0)
  for _, addr in ipairs(addrs) do
    assert(addr:ip() == '123.123.123.123')
    assert(addr:port() == 443)
  end

  -- local addrs = getaddrinfo:getaddrinfo('google.com', 'http')
  -- for _, addr in ipairs(addrs) do
  --   assert(addr:ip():match('^74%.'))
  --   assert(addr:port() == 80)
  -- end
end)
