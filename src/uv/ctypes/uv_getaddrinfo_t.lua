local ffi = require 'ffi'
local async = require 'uv/util/async'
local ctype = require 'uv/util/ctype'
local libuv = require 'uv/libuv'
local libc = require 'uv/libc'
local uv_loop_t = require 'uv/ctypes/uv_loop_t'
local verify = require 'uv/util/verify'

local AF_INET = 2
local AF_INET6 = 28

--------------------------------------------------------------------------------
-- sockaddr_in
--------------------------------------------------------------------------------

local sockaddr_in = ctype('struct sockaddr_in')

function sockaddr_in:ip()
  local buf = ffi.new('char[?]', 16)
  libuv.uv_ip4_name(self, buf, 16)
  return ffi.string(buf)
end

function sockaddr_in:port()
  return libc.ntohs(self.sin_port)
end

--------------------------------------------------------------------------------
-- uv_getaddrinfo_t
--------------------------------------------------------------------------------

local uv_getaddrinfo_t = ctype('uv_getaddrinfo_t', function(loop)
  local self = ffi.cast('uv_getaddrinfo_t*', libc.malloc(ffi.sizeof('uv_getaddrinfo_t')))
  self.loop = loop or libuv.uv_default_loop()
  return self
end)

function uv_getaddrinfo_t:free()
  libc.free(self)
end

function uv_getaddrinfo_t:getaddrinfo(node, service)
  local hints = ffi.new('struct addrinfo')
  -- hints.ai_family = AF_INET
  verify(libuv.uv_getaddrinfo(self.loop, self, async.uv_getaddrinfo_cb, node, service, hints))
  local status, addrinfo = async.yield(self)
  verify(status)
  local addrs = {}
  local ai = addrinfo
  while ai ~= ffi.NULL do
    if ai.ai_addr.sa_family == AF_INET then
      local addr = ffi.new('struct sockaddr_in')
      ffi.copy(addr, ai.ai_addr, ai.ai_addrlen)
      -- print('addr: ', addr.sin_p)
      table.insert(addrs, addr)
    end
    ai = ai.ai_next
  end
  libuv.uv_freeaddrinfo(addrinfo)
  return addrs
end

return uv_getaddrinfo_t
