require 'uv/ctypes/init'
local ffi = require 'ffi'
local timer = require 'uv.timer'
local libuv = require 'uv/libuv'
local libuv2 = require 'uv/libuv2'
local uv_idle_t = require 'uv/ctypes/uv_idle_t'
local uv_prepare_t = require 'uv/ctypes/uv_prepare_t'
local uv_check_t = require 'uv/ctypes/uv_check_t'
local join = require 'uv/util/join'

local loop = {}

function loop.run(callback)
  if callback then
    timer.set(0, callback)
  end
  return libuv.uv_default_loop():run()
end

function loop.alive()
  return libuv.uv_loop_alive(libuv.uv_default_loop()) ~= 0
end

function loop.stop()
  libuv.uv_default_loop():stop()
end

function loop.idle(callback)
  join(coroutine.create(function()
    uv_idle_t():start(callback)
  end))
end

function loop.yield(callback)
  join(coroutine.create(function()
    uv_prepare_t():start(callback)
  end))
end

function loop.resume(callback)
  join(coroutine.create(function()
    uv_check_t():start(callback)
  end))
end

return loop
