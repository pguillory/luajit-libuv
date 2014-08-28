require 'uv/cdef'
local ffi = require 'ffi'
local ctype = require 'uv/ctype'
local join = require 'uv/join'
local libuv = require 'uv/libuv'
local errno = require 'uv/errno'

--------------------------------------------------------------------------------
-- uv_loop_t
--------------------------------------------------------------------------------

local uv_loop_t = ctype('uv_loop_t')

function uv_loop_t:assert(r)
  if tonumber(r) < 0 then
    error(errno[r], 2)
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
