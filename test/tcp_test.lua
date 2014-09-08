require 'uv/util/strict'
local loop = require 'uv.loop'
local tcp = require 'uv.tcp'
local join = require 'uv/util/join'
local expect = require 'uv/util/expect'
local timer = require 'uv.timer'
local uv_tcp_t = require 'uv/ctypes/uv_tcp_t'

loop.run(function()
  local server = tcp.listen('127.0.0.1', 7000, function(client)
    assert(client:read() == 'ping')
    client:write('pong')
  end)

  local client = tcp.connect('127.0.0.1', 7000)
  client:write('ping')
  assert(client:read() == 'pong')
  client:close()

  server:close()
end)

-- loop.run(function()
--   local server = uv_tcp_t()
--   server:bind('127.0.0.1', 7000)
--   server:listen(function(stream)
--     expect.equal(stream:read(), 'foo')
--     stream:write('bar')
--   end)
-- 
--   local client = uv_tcp_t()
--   local stream = client:connect('127.0.0.1', 7000)
--   stream:write('foo')
--   expect.equal(stream:read(), 'bar')
--   stream:close()
-- 
--   server:close()
-- end)
-- 
-- loop.run(function()
--   local getaddrinfo = uv_getaddrinfo_t()
-- 
--   local addrs = getaddrinfo:getaddrinfo('123.123.123.123', 'https')
--   assert(#addrs > 0)
--   for _, addr in ipairs(addrs) do
--     expect.equal(addr:ip(), '123.123.123.123')
--     expect.equal(addr:port(), 443)
--   end
-- 
--   -- local addrs = getaddrinfo:getaddrinfo('google.com', 'http')
--   -- for _, addr in ipairs(addrs) do
--   --   assert(addr:ip():match('^74%.'))
--   --   assert(addr:port() == 80)
--   -- end
-- end)
