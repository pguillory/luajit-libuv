require 'uv/cdef'
local ffi = require 'ffi'
local async = require 'uv/async'
local ctype = require 'uv/ctype'
local libuv = require 'uv/libuv'

--------------------------------------------------------------------------------
-- uv_tcp_t
--------------------------------------------------------------------------------

local uv_tcp_t = ctype('uv_tcp_t')

function uv_tcp_t:bind(ip, port)
  local addr = ffi.new('struct sockaddr_in')
  libuv.uv_ip4_addr(ip, port, addr)
  libuv.uv_tcp_bind(self, ffi.cast('struct sockaddr*', addr), 0)
end

uv_tcp_t.connect = async.func('uv_connect_cb', function(yield, callback, self, ip, port)
  local socket = self.loop:tcp()
  local connect = ffi.new('uv_connect_t')
  local addr = ffi.new('struct sockaddr_in')
  libuv.uv_ip4_addr(ip, port, addr)

  libuv.uv_tcp_connect(connect, socket, ffi.cast('struct sockaddr*', addr), callback)
  local status = yield(connect)
  if status < 0 then
    self.loop:assert(status)
  end
  return connect
end)

uv_tcp_t.listen = async.server('uv_connection_cb', function(yield, callback, self, on_connect)
  self.loop:assert(libuv.uv_listen(ffi.cast('uv_stream_t*', self), 128, callback))
  yield(self, function(self, status)
    if tonumber(status) >= 0 then
      local client = self.loop:tcp()
      if 0 == tonumber(libuv.uv_accept(self, ffi.cast('uv_stream_t*', client))) then
        return on_connect(ffi.cast('uv_stream_t*', client))
      else
        client:close()
      end
    end
  end)
end)

uv_tcp_t.close = async.func('uv_close_cb', function(yield, callback, self)
  libuv.uv_close(ffi.cast('uv_handle_t*', self), callback)
  yield(self)
end)

-- int uv_tcp_getsockname(const uv_tcp_t* handle, struct sockaddr* name, int* namelen);

uv_tcp_t.getsockname = function(self)
  local addr = ffi.new('struct sockaddr')
  local len = ffi.new('int[1]')
  len[0] = ffi.sizeof(addr)
  local buf = ffi.C.malloc(4096)
  self.loop:assert(libuv.uv_tcp_getsockname(self, addr, len))
  self.loop:assert(libuv.uv_ip4_name(ffi.cast('struct sockaddr_in*', addr), buf, 4096))
  local peername = ffi.string(buf)
  ffi.C.free(buf)
  return peername
end

-- int uv_tcp_getpeername(const uv_tcp_t* handle, struct sockaddr* name, int* namelen);
-- int uv_ip4_name(const struct sockaddr_in* src, char* dst, size_t size);

uv_tcp_t.getpeername = function(self)
  local addr = ffi.new('struct sockaddr')
  local len = ffi.new('int[1]')
  len[0] = ffi.sizeof(addr)
  local buf = ffi.C.malloc(4096)
  self.loop:assert(libuv.uv_tcp_getpeername(self, addr, len))
  self.loop:assert(libuv.uv_ip4_name(ffi.cast('struct sockaddr_in*', addr), buf, 4096))
  local peername = ffi.string(buf)
  ffi.C.free(buf)
  return peername
end


return uv_tcp_t
