require 'uv/cdef'
local ffi = require 'ffi'
local async = require 'async'
local ctype = require 'ctype'
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

uv_tcp_t.connect = async.func(function(yield, callback, self, ip, port)
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

uv_tcp_t.listen = async.server(function(yield, callback, self, on_connect)
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

uv_tcp_t.close = async.func(function(yield, callback, self)
  libuv.uv_close(ffi.cast('uv_handle_t*', self), callback)
  yield(self)
end)

return uv_tcp_t
