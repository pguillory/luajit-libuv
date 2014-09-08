require 'uv/ctypes/init'
local class = require 'uv/util/class'
local ffi = require 'ffi'
local libuv = require 'uv/libuv'
local libuv2 = require 'uv/libuv2'
local uv_tcp_t = require 'uv/ctypes/uv_tcp_t'
local join = require 'uv/util/join'

local tcp = {}

function tcp.listen(host, port, callback)
  local server = uv_tcp_t()
  server:bind(host, port)
  server:listen()
  return server
end

function tcp.connect(host, port, callback)
  local client = uv_tcp_t()
  return client:connect(host, tonumber(port))
end

return tcp
