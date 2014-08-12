require 'uv/cdef'
local ffi = require 'ffi'
local async = require 'uv/async'
local ctype = require 'uv/ctype'
local libuv = require 'uv/libuv'

--------------------------------------------------------------------------------
-- uv_stream_t
--------------------------------------------------------------------------------

local uv_stream_t = ctype('uv_stream_t')

local alloc_cb = ffi.cast('uv_alloc_cb', function(handle, suggested_size, buf)
  buf.base = ffi.C.malloc(suggested_size)
  buf.len = suggested_size
end)

uv_stream_t.read = async.func('uv_read_cb', function(yield, callback, self)
  libuv.uv_read_start(ffi.cast('uv_stream_t*', self), alloc_cb, callback)
  local nread, buf = yield(self)
  libuv.uv_read_stop(ffi.cast('uv_stream_t*', self))
  local chunk = (nread < 0) and '' or ffi.string(buf.base, nread)
  ffi.C.free(buf.base)
  return chunk
end)

uv_stream_t.write = async.func('uv_write_cb', function(yield, callback, self, content)
  local req = ffi.new('uv_write_t')
  local buf = ffi.new('uv_buf_t')
  buf.base = ffi.cast('char*', content)
  buf.len = #content
  -- local buf = libuv.uv_buf_init(s, #s)
  local r = libuv.uv_write(req, ffi.cast('uv_stream_t*', self), buf, 1, callback)
  local status = yield(req)
  if tonumber(status) ~= 0 then
    -- if not self:is_closing() then
    --   self:close()
    -- end
    self.loop:assert(status)
    -- if not libuv.uv_is_closing(ffi.cast('uv_handle_t*', self.handle)) then
    --   libuv.uv_close((uv_handle_t*) req->handle, on_close)
    -- end
  end
  -- ffi.C.free(req)
  -- ffi.C.free(buf)
end)

uv_stream_t.close = async.func('uv_close_cb', function(yield, callback, self)
  libuv.uv_close(ffi.cast('uv_handle_t*', self), callback)
  yield(self)
end)

return uv_stream_t
