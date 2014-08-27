require 'uv/cdef'
local ffi = require 'ffi'
local libuv = require 'uv/libuv'

local uv_fs_t = require 'uv/uv_fs_t'
local uv_getaddrinfo_t = require 'uv/uv_getaddrinfo_t'
local uv_loop_t = require 'uv/uv_loop_t'
local uv_stream_t = require 'uv/uv_stream_t'
local uv_tcp_t = require 'uv/uv_tcp_t'
local uv_timer_t = require 'uv/uv_timer_t'

--------------------------------------------------------------------------------
-- uv
--------------------------------------------------------------------------------

local uv = {}

uv.timer = require 'uv.timer'
uv.fs = require 'uv.fs'
uv.http = require 'uv.http'
uv.url = require 'uv.url'

function uv.run(callback)
  if callback then
    uv.timer.set(0, callback)
  end
  return libuv.uv_default_loop():run()
end

return uv
