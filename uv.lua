require 'strict'
local ffi = require 'ffi'
local async = require 'async'
local class = require 'class'
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
  local tcp = ffi.new('uv_tcp_t')
  libuv.uv_tcp_init(self, tcp)
  return tcp
end

function Loop:fs()
  local fs = ffi.new('uv_fs_t')
  fs.loop = self
  return fs
end

function Loop:timer()
  local timer = ffi.new('uv_timer_t')
  libuv.uv_timer_init(self, timer)
  return timer
end

--------------------------------------------------------------------------------
-- Fs
--------------------------------------------------------------------------------

local Fs = ctype('uv_fs_t')

Fs.open = async.func(function(yield, callback, self, path)
  libuv.uv_fs_open(self.loop, self, path, 0, 0, callback)
  yield(self)
  local descriptor = tonumber(self.result)
  if descriptor < 0 then
    return error('error opening file: ' .. tonumber(self.errorno))
  end
  -- print('opened file ', descriptor)
  -- libuv.uv_fs_req_cleanup(self)
  -- return File(descriptor)
  return self
end)

Fs.read = async.func(function(yield, callback, self)
  -- local req = ffi.new('uv_fs_t')
  local buf = ffi.new('char[?]', 4096)
  -- print('reading file ', self.result)
  local descriptor = self.result
  libuv.uv_fs_read(self.loop, self, descriptor, buf, 4096, -1, callback);
  yield(self)
  local nread = tonumber(self.result)
  self.result = descriptor
  -- print('result now: ', self.result)
  if nread < 0 then
    return error('error reading file: ' .. tonumber(self.errorno))
  else
    return ffi.string(buf, nread)
  end
end)

function Fs:close()
end

--------------------------------------------------------------------------------
-- Timer
--------------------------------------------------------------------------------

local Timer = ctype('uv_timer_t')

function Timer:start(callback, timeout, repeat_time)
  return self.loop:assert(libuv.uv_timer_start(self, callback, timeout or 0, repeat_time or 0))
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

Tcp.read = async.func(function(yield, callback, self)
  libuv2.lua_uv_read_start(ffi.cast('uv_stream_t*', self), libuv2.lua_uv_alloc, callback)
  local nread, buf_base, buf_len = yield(self)
  libuv.uv_read_stop(ffi.cast('uv_stream_t*', self))
  return ffi.string(buf_base, nread)
end)

Tcp.write = async.func(function(yield, callback, self, content)
  local req = ffi.new('uv_write_t')
  local buf = ffi.new('uv_buf_t')
  buf.base = ffi.cast('char*', content)
  buf.len = #content
  -- local buf = libuv.uv_buf_init(s, #s)
  assert(0 == tonumber(libuv.uv_write(req, ffi.cast('uv_stream_t*', self), buf, 1, callback)))
  local status = yield(req)
  if tonumber(status) ~= 0 then
    print('write error: ', libuv.uv_err_name(status), libuv.uv_strerror(status))
    if not self:is_closing() then
      self:close()
    end
    -- if not libuv.uv_is_closing(ffi.cast('uv_handle_t*', self.handle)) then
    --   libuv.uv_close((uv_handle_t*) req->handle, on_close)
    -- end
  end
  -- ffi.C.free(req)
  -- ffi.C.free(buf)
end)

Tcp.listen = async.server(function(callback, self, on_connect)
  self.loop:assert(libuv.uv_listen(ffi.cast('uv_stream_t*', self), 128, callback))
  return self, function(self, status)
    if tonumber(status) >= 0 then
      local client = self.loop:tcp()
      if self:accept(client) then
        on_connect(client)
      else
        client:close()
      end
    end
  end
end)

function Tcp:close()
  libuv.uv_close(ffi.cast('uv_handle_t*', self), nil)
end

--------------------------------------------------------------------------------
-- uv
--------------------------------------------------------------------------------

local uv = {}

function uv.run(main)
  local thread = coroutine.create(main)
  local loop = libuv.uv_default_loop()
  local timer = loop:timer()
  timer:start(function()
    assert(coroutine.resume(thread))
  end)
  loop:run()
end

function uv.fs()
  return libuv.uv_default_loop():fs()
end

function uv.tcp()
  return libuv.uv_default_loop():tcp()
end

return uv
