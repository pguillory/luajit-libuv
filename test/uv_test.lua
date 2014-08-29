require 'uv/util/strict'
local uv = require 'uv'
local uv_tcp_t = require 'uv/ctypes/uv_tcp_t'
local uv_getaddrinfo_t = require 'uv/ctypes/uv_getaddrinfo_t'
local expect = require 'uv/util/expect'

for i = 1, 1000 do
  uv.run(function()
  end)
end

uv.run(function()
  local server = uv_tcp_t()
  server:bind('127.0.0.1', 7000)
  server:listen(function(stream)
    expect.equal(stream:read(), 'foo')
    stream:write('bar')
  end)

  local client = uv_tcp_t()
  local stream = client:connect('127.0.0.1', 7000)
  stream:write('foo')
  expect.equal(stream:read(), 'bar')
  stream:close()

  server:close()
end)

uv.run(function()
  local getaddrinfo = uv_getaddrinfo_t()

  local addrs = getaddrinfo:getaddrinfo('123.123.123.123', 'https')
  assert(#addrs > 0)
  for _, addr in ipairs(addrs) do
    expect.equal(addr:ip(), '123.123.123.123')
    expect.equal(addr:port(), 443)
  end

  -- local addrs = getaddrinfo:getaddrinfo('google.com', 'http')
  -- for _, addr in ipairs(addrs) do
  --   assert(addr:ip():match('^74%.'))
  --   assert(addr:port() == 80)
  -- end
end)

do
  local free, total = uv.free_memory(), uv.total_memory()
  assert(free > 0)
  assert(total > 0)
  assert(free <= total)
end

do
  local hrtime = uv.hrtime()
  assert(hrtime > 0)
end

do
  local x, y, z = uv.loadavg()
  assert(type(x) == 'number')
  assert(type(y) == 'number')
  assert(type(z) == 'number')
end
