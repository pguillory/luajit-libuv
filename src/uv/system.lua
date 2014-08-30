require 'uv/ctypes/init'
local ffi = require 'ffi'
local libuv = require 'uv/libuv'
local libuv2 = require 'uv/libuv2'
local verify = require 'uv/util/verify'

local system = {}

function system.free_memory()
  return libuv.uv_get_free_memory()
end

function system.total_memory()
  return libuv.uv_get_total_memory()
end

function system.hrtime()
  return libuv.uv_hrtime()
end

function system.loadavg()
  local avg = ffi.new('double[?]', 3)
  libuv.uv_loadavg(avg)
  return avg[0], avg[1], avg[2]
end

function system.uptime()
  local time = ffi.new('double[1]')
  verify(libuv.uv_uptime(time))
  return time[0]
end

return system
