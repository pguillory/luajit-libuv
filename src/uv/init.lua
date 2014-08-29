require 'uv/ctypes/init'
local ffi = require 'ffi'
local libuv = require 'uv/libuv'
local libuv2 = require 'uv/libuv2'
local uv_buf_t = require 'uv/ctypes/uv_buf_t'

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

function uv.free_memory()
  return libuv.uv_get_free_memory()
end

function uv.total_memory()
  return libuv.uv_get_total_memory()
end

function uv.hrtime()
  return libuv.uv_hrtime()
end

function uv.exe_path()
  local buf = uv_buf_t()
  local status = libuv2.uv2_exepath(buf)
  assert(status == 0)
  local result = ffi.string(buf.base, buf.len)
  buf:free()
  return result
end

function uv.loadavg()
  local avg = ffi.new('double[?]', 3)
  libuv.uv_loadavg(avg)
  return avg[0], avg[1], avg[2]
end

return uv
