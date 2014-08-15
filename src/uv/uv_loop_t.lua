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

function uv_loop_t:run(callback)
  join(coroutine.create(function()
    self:timer():sleep(0)
    return callback()
  end))
  self:assert(libuv.uv_run(self, libuv.UV_RUN_DEFAULT))
end

function uv_loop_t:stop()
  libuv.uv_stop(self)
end

function uv_loop_t:timer()
  local timer = ffi.new('uv_timer_t')
  libuv.uv_timer_init(self, timer)
  return timer
end

-- function uv_loop_t:addr(host, port, service)
--     local addr = ffi.new('struct sockaddr_in')
--     self:assert(libuv.uv_ip4_addr(host, port, addr))
--     return addr
--   else
--     local getaddrinfo = ffi.new('uv_getaddrinfo_t')
--     getaddrinfo.loop = self
--     return getaddrinfo:getaddrinfo(node, service)
--   end
-- end

function uv_loop_t:getaddrinfo()
  local getaddrinfo = ffi.new('uv_getaddrinfo_t')
  getaddrinfo.loop = self
  return getaddrinfo
end

return uv_loop_t
