require 'uv/cdef'
local ffi = require 'ffi'
local async = require 'uv/async'
local async2 = require 'uv/async2'
local ctype = require 'uv/ctype'
local libuv = require 'uv/libuv'
local libuv2 = require 'uv/libuv2'

--------------------------------------------------------------------------------
-- uv_tcp_t
--------------------------------------------------------------------------------

local uv_tcp_t = ctype('uv_tcp_t')

function uv_tcp_t:bind(host, port)
  local addr = ffi.new('struct sockaddr_in')
  libuv.uv_ip4_addr(host, port, addr)
  addr = ffi.cast('struct sockaddr*', addr)
  libuv.uv_tcp_bind(self, addr, 0)
end

function uv_tcp_t:connect(host, port)
  local socket = self.loop:tcp()
  local connect = ffi.new('uv_connect_t')
  local addr = ffi.new('struct sockaddr_in')
  if libuv.uv_ip4_addr(host, port, addr) ~= 0 then
    addr = self.loop:getaddrinfo():getaddrinfo(host, tostring(port))[1]
  end
  addr = ffi.cast('struct sockaddr*', addr)

  self.loop:assert(libuv.uv_tcp_connect(connect, socket, addr, async2.uv_connect_cb))
  local status = async2.yield(connect)
  if status < 0 then
    self.loop:assert(status)
  end
  return connect
end

function uv_tcp_t:read()
  libuv2.uv2_tcp_read_start(self, libuv2.uv2_alloc_cb, async2.uv_read_cb)
  local nread, buf = async2.yield(self)
  libuv2.uv2_tcp_read_stop(self)
  local chunk = (nread < 0) and '' or ffi.string(buf.base, nread)
  ffi.C.free(buf.base)
  return chunk, nread
end

function uv_tcp_t:write(content)
  local req = ffi.new('uv_write_t')
  local buf = ffi.new('uv_buf_t')
  buf.base = ffi.cast('char*', content)
  buf.len = #content
  self.loop:assert(libuv2.uv2_tcp_write(req, self, buf, 1, async2.uv_write_cb))
  self.loop:assert(async2.yield(req))
end

uv_tcp_t.listen = async.server('uv_connection_cb', function(yield, callback, self, on_connect)
  self.loop:assert(libuv2.uv2_tcp_listen(self, 128, callback))
  yield(self, function(self, status)
    if tonumber(status) >= 0 then
      local client = self.loop:tcp()
      if 0 == tonumber(libuv2.uv2_tcp_accept(self, client)) then
        on_connect(client)
      end
      client:close()
    end
  end)
end)

function uv_tcp_t:close()
  libuv2.uv2_tcp_close(self, async2.uv_close_cb)
  async2.yield(self)
end

function uv_tcp_t:getsockname()
  local addr = ffi.new('struct sockaddr')
  local len = ffi.new('int[1]')
  len[0] = ffi.sizeof(addr)
  local buf = ffi.C.malloc(4096)
  self.loop:assert(libuv.uv_tcp_getsockname(self, addr, len))
  addr = ffi.cast('struct sockaddr_in*', addr)
  self.loop:assert(libuv.uv_ip4_name(addr, buf, 4096))
  local peername = ffi.string(buf)
  ffi.C.free(buf)
  return peername
end

function uv_tcp_t:getpeername()
  local addr = ffi.new('struct sockaddr')
  local len = ffi.new('int[1]')
  len[0] = ffi.sizeof(addr)
  local buf = ffi.C.malloc(4096)
  self.loop:assert(libuv.uv_tcp_getpeername(self, addr, len))
  addr = ffi.cast('struct sockaddr_in*', addr)
  self.loop:assert(libuv.uv_ip4_name(addr, buf, 4096))
  local peername = ffi.string(buf)
  ffi.C.free(buf)
  return peername
end

return uv_tcp_t
