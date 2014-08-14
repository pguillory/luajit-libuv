require 'uv/cdef'
local ffi = require 'ffi'
local async = require 'uv/async'
local async2 = require 'uv/async2'
local ctype = require 'uv/ctype'
local libuv = require 'uv/libuv'
local libuv2 = require 'uv/libuv2'

--------------------------------------------------------------------------------
-- uv_stream_t
--------------------------------------------------------------------------------

local uv_stream_t = ctype('uv_stream_t')

function uv_stream_t:read()
  libuv.uv_read_start(self, libuv2.uv2_alloc_cb, async2.uv_read_cb)
  local nread, buf = async2.yield(self)
  libuv.uv_read_stop(self)
  local chunk = (nread < 0) and '' or ffi.string(buf.base, nread)
  ffi.C.free(buf.base)
  return chunk, nread
end

function uv_stream_t:write(content)
  local req = ffi.new('uv_write_t')
  local buf = ffi.new('uv_buf_t')
  buf.base = ffi.cast('char*', content)
  buf.len = #content
  self.loop:assert(libuv.uv_write(req, self, buf, 1, async2.uv_write_cb))
  self.loop:assert(async2.yield(req))
end

function uv_stream_t:close()
  libuv2.uv2_stream_close(self, async2.uv_close_cb)
  async2.yield(self)
end

return uv_stream_t
