require 'uv/ctypes/init'
local ffi = require 'ffi'
local timer = require 'uv.timer'
local libuv = require 'uv/libuv'
local libuv2 = require 'uv/libuv2'

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
  return libuv.uv_stop(libuv.uv_default_loop())
end

return loop
