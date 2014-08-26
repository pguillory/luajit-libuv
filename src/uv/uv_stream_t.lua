require 'uv/cdef'
local ffi = require 'ffi'
local async = require 'uv/async'
local async = require 'uv/async'
local ctype = require 'uv/ctype'
local libuv = require 'uv/libuv'
local libuv2 = require 'uv/libuv2'
local uv_buf_t = require 'uv/uv_buf_t'
local uv_write_t = require 'uv/uv_write_t'

--------------------------------------------------------------------------------
-- uv_stream_t
--------------------------------------------------------------------------------

local uv_stream_t = ctype('uv_stream_t')

function uv_stream_t:read()
  libuv.uv_read_start(self, libuv2.uv2_alloc_cb, async.uv_read_cb)
  local nread, buf = async.yield(self)
  libuv.uv_read_stop(self)
  self.loop:assert(nread)
  local chunk = (nread < 0) and '' or ffi.string(buf.base, nread)
  ffi.C.free(buf.base)
  return chunk, nread
end

function uv_stream_t:write(content)
  local req = uv_write_t()
  local buf = uv_buf_t(content, #content)
  self.loop:assert(libuv.uv_write(req, self, buf, 1, async.uv_write_cb))
  self.loop:assert(async.yield(req))
  req:free()
  buf:free()
end

function uv_stream_t:close()
  libuv2.uv2_stream_close(self, async.uv_close_cb)
  async.yield(self)
end

return uv_stream_t
