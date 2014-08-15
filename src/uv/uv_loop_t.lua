require 'uv/cdef'
local ffi = require 'ffi'
local ctype = require 'uv/ctype'
local join = require 'uv/join'
local libuv = require 'uv/libuv'

--------------------------------------------------------------------------------
-- uv_loop_t
--------------------------------------------------------------------------------

local uv_loop_t = ctype('uv_loop_t')

function uv_loop_t:assert(r)
  if tonumber(r) < 0 then
    error(ffi.string(libuv.uv_err_name(r)) .. ': ' .. ffi.string(libuv.uv_strerror(r)), 2)
  end
  return tonumber(r)
end

function uv_loop_t:run()
  self:assert(libuv.uv_run(self, libuv.UV_RUN_DEFAULT))
end

function uv_loop_t:stop()
  libuv.uv_stop(self)
end

return uv_loop_t
