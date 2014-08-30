local ffi = require 'ffi'
local ctype = require 'uv/util/ctype'
local join = require 'uv/util/join'
local libuv = require 'uv/libuv'
local verify = require 'uv/util/verify'

--------------------------------------------------------------------------------
-- uv_loop_t
--------------------------------------------------------------------------------

local uv_loop_t = ctype('uv_loop_t')

function uv_loop_t:run()
  verify(libuv.uv_run(self, libuv.UV_RUN_DEFAULT))
end

function uv_loop_t:stop()
  libuv.uv_stop(self)
end

return uv_loop_t
