require 'uv/cdef'
local ffi = require 'ffi'
local async = require 'async'
local ctype = require 'ctype'
local libuv = require 'uv/libuv'

--------------------------------------------------------------------------------
-- uv_loop_t
--------------------------------------------------------------------------------

local uv_loop_t = ctype('uv_loop_t')

function uv_loop_t:assert(r)
  if tonumber(r) ~= 0 then
    error(self:last_error(), 2)
  end
end

function uv_loop_t:run(callback)
  self:timer():start(function()
    assert(coroutine.resume(coroutine.create(callback)))
  end)
  libuv.uv_run(self, libuv.UV_RUN_DEFAULT)
end

function uv_loop_t:tcp()
  local tcp = ffi.new('uv_tcp_t')
  libuv.uv_tcp_init(self, tcp)
  return tcp
end

function uv_loop_t:fs()
  local fs = ffi.new('uv_fs_t')
  fs.loop = self
  return fs
end

function uv_loop_t:timer()
  local timer = ffi.new('uv_timer_t')
  libuv.uv_timer_init(self, timer)
  return timer
end

function uv_loop_t:last_error()
  local error = libuv.uv_last_error(self)
  return ffi.string(libuv.uv_err_name(error)) .. ': ' .. ffi.string(libuv.uv_strerror(error))
end

return uv_loop_t
