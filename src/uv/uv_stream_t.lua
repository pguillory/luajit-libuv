require 'uv/cdef'
local ffi = require 'ffi'
local async = require 'uv/async'
local ctype = require 'uv/ctype'
local libuv = require 'uv/libuv'
local libuv2 = require 'uv/libuv2'

--------------------------------------------------------------------------------
-- uv_stream_t
--------------------------------------------------------------------------------

local uv_stream_t = ctype('uv_stream_t')

uv_stream_t.read = async.func('uv_read_cb', function(yield, callback, self)
  libuv.uv_read_start(self, libuv2.uv2_alloc_cb, callback)
  local nread, buf = yield(self)
  libuv.uv_read_stop(self)
  local chunk = (nread < 0) and '' or ffi.string(buf.base, nread)
  ffi.C.free(buf.base)
  return chunk, nread
end)

uv_stream_t.write = async.func('uv_write_cb', function(yield, callback, self, content)
  local req = ffi.new('uv_write_t')
  local buf = ffi.new('uv_buf_t')
  buf.base = ffi.cast('char*', content)
  buf.len = #content
  self.loop:assert(libuv.uv_write(req, self, buf, 1, callback))
  self.loop:assert(yield(req))
end)

uv_stream_t.close = async.func('uv_close_cb', function(yield, callback, self)
  libuv2.uv2_stream_close(self, callback)
  yield(self)
end)

return uv_stream_t
