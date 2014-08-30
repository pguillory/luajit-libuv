require 'uv/ctypes/init'
local ffi = require 'ffi'
local libuv = require 'uv/libuv'
local libuv2 = require 'uv/libuv2'

local uv = {}

uv.fs = require 'uv.fs'
uv.http = require 'uv.http'
uv.parallel = require 'uv.parallel'
uv.process = require 'uv.process'
uv.system = require 'uv.system'
uv.timer = require 'uv.timer'
uv.url = require 'uv.url'

function uv.run(callback)
  if callback then
    uv.timer.set(0, callback)
  end
  return libuv.uv_default_loop():run()
end

function uv.alive()
  return libuv.uv_loop_alive(libuv.uv_default_loop()) ~= 0
end

function uv.stop()
  return libuv.uv_stop(libuv.uv_default_loop())
end

return uv
