local ffi = require 'ffi'
local async = require 'uv/util/async'
local ctype = require 'uv/util/ctype'
local libuv = require 'uv/libuv'
local libuv2 = require 'uv/libuv2'
local libc = require 'uv/libc'
local uv_buf_t = require 'uv/ctypes/uv_buf_t'
local uv_write_t = require 'uv/ctypes/uv_write_t'
local uv_loop_t = require 'uv/ctypes/uv_loop_t'
local verify = require 'uv/util/verify'

--------------------------------------------------------------------------------
-- uv_stream_t
--------------------------------------------------------------------------------

local uv_stream_t = ctype('uv_stream_t')

function uv_stream_t:read()
  libuv.uv_read_start(self, libuv2.uv2_alloc_cb, async.uv_read_cb)
  local nread, buf = async.yield(self)
  libuv.uv_read_stop(self)
  verify(nread)
  local chunk = (nread < 0) and '' or ffi.string(buf.base, nread)
  libc.free(buf.base)
  return chunk, nread
end

function uv_stream_t:write(content)
  local req = uv_write_t()
  local buf = uv_buf_t(content, #content)
  verify(libuv.uv_write(req, self, buf, 1, async.uv_write_cb))
  verify(async.yield(req))
  req:free()
  buf:free()
end

function uv_stream_t:close()
  libuv2.uv2_stream_close(self, async.uv_close_cb)
  async.yield(self)
end

return uv_stream_t
