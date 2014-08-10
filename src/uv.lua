require 'uv/cdef'
local ffi = require 'ffi'
local libuv = require 'uv/libuv'
local libuv2 = require 'uv/libuv2'

local uv_fs_t = require 'uv/uv_fs_t'
local uv_loop_t = require 'uv/uv_loop_t'
local uv_statbuf_t = require 'uv/uv_statbuf_t'
local uv_stream_t = require 'uv/uv_stream_t'
local uv_tcp_t = require 'uv/uv_tcp_t'
local uv_timer_t = require 'uv/uv_timer_t'

--------------------------------------------------------------------------------
-- uv
--------------------------------------------------------------------------------

local uv = {}

uv.loop = libuv.uv_default_loop()

function uv.run(callback)
  return uv.loop:run(callback)
end

function uv.fs()
  return uv.loop:fs()
end

function uv.tcp()
  return uv.loop:tcp()
end

return uv
