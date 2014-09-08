local ffi = require 'ffi'
local async = require 'uv/util/async'
local ctype = require 'uv/util/ctype'
local join = require 'uv/util/join'
local libuv = require 'uv/libuv'
local libuv2 = require 'uv/libuv2'
local libc = require 'uv/libc'
local uv_buf_t = require 'uv/ctypes/uv_buf_t'
local uv_connect_t = require 'uv/ctypes/uv_connect_t'
local uv_getaddrinfo_t = require 'uv/ctypes/uv_getaddrinfo_t'
local uv_loop_t = require 'uv/ctypes/uv_loop_t'
local verify = require 'uv/util/verify'

--------------------------------------------------------------------------------
-- uv_tcp_t
--------------------------------------------------------------------------------

local uv_tcp_t = ctype('uv_tcp_t', function(loop)
  local self = ffi.cast('uv_tcp_t*', libc.malloc(ffi.sizeof('uv_tcp_t')))
  libuv.uv_tcp_init(loop or libuv.uv_default_loop(), self)
  return self
end)

function uv_tcp_t:bind(host, port)
  local addr = ffi.new('struct sockaddr_in')
  libuv.uv_ip4_addr(host, port, addr)
  addr = ffi.cast('struct sockaddr*', addr)
  libuv.uv_tcp_bind(self, addr, 0)
end

function uv_tcp_t:connect(host, port)
  local socket = uv_tcp_t(self.loop)
  local connect = uv_connect_t()
  local addr = ffi.new('struct sockaddr_in')
  if libuv.uv_ip4_addr(host, port, addr) ~= 0 then
    local gai = uv_getaddrinfo_t(self.loop)
    addr = gai:getaddrinfo(host, tostring(port))[1]
    gai:free()
  end
  addr = ffi.cast('struct sockaddr*', addr)

  verify(libuv.uv_tcp_connect(connect, socket, addr, async.uv_connect_cb))
  local status = async.yield(connect)
  if status < 0 then
    verify(status)
  end
  local handle = connect.handle
  connect:free()
  return handle
end

function uv_tcp_t:read()
  libuv2.uv2_tcp_read_start(self, libuv2.uv2_alloc_cb, async.uv_read_cb)
  local nread, buf = async.yield(self)
  libuv2.uv2_tcp_read_stop(self)
  verify(nread)
  local chunk = (nread < 0) and '' or ffi.string(buf.base, nread)
  libc.free(buf.base)
  return chunk, nread
end

function uv_tcp_t:write(content)
  local req = ffi.new('uv_write_t')
  local buf = uv_buf_t(content, #content)
  verify(libuv2.uv2_tcp_write(req, self, buf, 1, async.uv_write_cb))
  local status = async.yield(req)
  buf:free()
  return 0 == status
end

function uv_tcp_t:listen()
  verify(libuv2.uv2_tcp_listen(self, 128, async.uv_connection_cb))
end

function uv_tcp_t:accept()
  local status = async.yield(self)
  if status >= 0 then
    local socket = uv_tcp_t()
    if 0 == tonumber(libuv2.uv2_tcp_accept(self, socket)) then
      return socket
    end
  end
end

function uv_tcp_t:close()
  libuv2.uv2_tcp_close(self, async.uv_close_cb)
  async.yield(self)
  libc.free(self)
end

function uv_tcp_t:getsockname()
  local addr = ffi.new('struct sockaddr')
  local len = ffi.new('int[1]')
  len[0] = ffi.sizeof(addr)
  local buf = libc.malloc(4096)
  verify(libuv.uv_tcp_getsockname(self, addr, len))
  addr = ffi.cast('struct sockaddr_in*', addr)
  verify(libuv.uv_ip4_name(addr, buf, 4096))
  local peername = ffi.string(buf)
  libc.free(buf)
  return peername
end

function uv_tcp_t:getpeername()
  local addr = ffi.new('struct sockaddr')
  local len = ffi.new('int[1]')
  len[0] = ffi.sizeof(addr)
  local buf = libc.malloc(4096)
  verify(libuv.uv_tcp_getpeername(self, addr, len))
  addr = ffi.cast('struct sockaddr_in*', addr)
  verify(libuv.uv_ip4_name(addr, buf, 4096))
  local peername = ffi.string(buf)
  libc.free(buf)
  return peername
end

return uv_tcp_t
