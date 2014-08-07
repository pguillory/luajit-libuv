local ffi = require 'ffi'
local ctype = require 'ctype'

do
  -- local dir = debug.getinfo(1).source:match('@(.*/)') or ''
  ffi.cdef(io.open('uv2.min.h'):read('*a'))
end

local libuv = ffi.load('uv')
local libuv2 = ffi.load('uv2')

--------------------------------------------------------------------------------
-- Loop
--------------------------------------------------------------------------------

local Loop = ctype('uv_loop_t')

function Loop:assert(r)
  if tonumber(r) ~= 0 then
    error(libuv.uv_err_name(libuv.uv_last_error(self)))
  end
end

function Loop:run()
  return libuv.uv_run(self, libuv.UV_RUN_DEFAULT)
end

function Loop:tcp()
  local server = ffi.new('uv_tcp_t')
  libuv.uv_tcp_init(self, server)
  return server
end

--------------------------------------------------------------------------------
-- Stream
--------------------------------------------------------------------------------

local Stream = ctype('uv_stream_t')

function Stream:accept(client)
  return 0 == tonumber(libuv.uv_accept(self, ffi.cast('uv_stream_t*', client)))
end

--------------------------------------------------------------------------------
-- Tcp
--------------------------------------------------------------------------------

local Tcp = ctype('uv_tcp_t')

function Tcp:bind(ip, port)
  libuv.uv_tcp_bind(self, libuv.uv_ip4_addr(ip, port))
end

function Tcp:listen(on_connect)
  self.loop:assert(libuv.uv_listen(ffi.cast('uv_stream_t*', self), 128, on_connect))
end

function Tcp:read(on_read)
  libuv2.lua_uv_read_start(ffi.cast('uv_stream_t*', self), libuv2.lua_uv_alloc, on_read)
end

function Tcp:close()
  libuv.uv_close(ffi.cast('uv_handle_t*', self), nil)
end

--------------------------------------------------------------------------------
-- uv
--------------------------------------------------------------------------------

local uv = {}

uv.default_loop = libuv.uv_default_loop

return uv
