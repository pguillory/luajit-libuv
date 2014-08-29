require 'uv/ctypes/init'
local ffi = require 'ffi'
local libuv = require 'uv/libuv'
local libuv2 = require 'uv/libuv2'

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

function uv.alive()
  return libuv.uv_loop_alive(libuv.uv_default_loop()) ~= 0
end

function uv.stop()
  return libuv.uv_stop(libuv.uv_default_loop())
end

function uv.free_memory()
  return libuv.uv_get_free_memory()
end

function uv.total_memory()
  return libuv.uv_get_total_memory()
end

function uv.hrtime()
  return libuv.uv_hrtime()
end

function uv.loadavg()
  local avg = ffi.new('double[?]', 3)
  libuv.uv_loadavg(avg)
  return avg[0], avg[1], avg[2]
end

return uv
