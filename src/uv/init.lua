require 'uv/ctypes/init'
local ffi = require 'ffi'
local libuv = require 'uv/libuv'

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
