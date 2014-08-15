require 'uv/cdef'
local ffi = require 'ffi'
local async = require 'uv/async'
local async = require 'uv/async'
local ctype = require 'uv/ctype'
local libuv = require 'uv/libuv'

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
  return ffi.C.ntohs(self.sin_port)
end

--------------------------------------------------------------------------------
-- uv_getaddrinfo_t
--------------------------------------------------------------------------------

local uv_getaddrinfo_t = ctype('uv_getaddrinfo_t', function(loop)
  local self = ffi.cast('uv_getaddrinfo_t*', ffi.C.malloc(ffi.sizeof('uv_getaddrinfo_t')))
  self.loop = loop or libuv.uv_default_loop()
  return self
end)

ffi.cdef [[ uint16_t ntohs(uint16_t netshort); ]]

function uv_getaddrinfo_t:getaddrinfo(node, service)
  local hints = ffi.new('struct addrinfo')
  -- hints.ai_family = AF_INET
  self.loop:assert(libuv.uv_getaddrinfo(self.loop, self, async.uv_getaddrinfo_cb, node, service, hints))
  local status, addrinfo = async.yield(self)
  self.loop:assert(status)
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
