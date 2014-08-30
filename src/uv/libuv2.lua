local ffi = require 'ffi'

local dir = debug.getinfo(1).source:match('@(.*/)') or '.'

do
  local file = io.open(dir .. 'libuv2.h')
  if not file then
    error('libuv2.h not found')
  end
  local header = file:read('*a')
  ffi.cdef(header)
  file:close()
end

local ok, lib = pcall(function() return ffi.load(dir .. 'lib/libuv2.dylib') end)
if ok and lib then return lib end

local ok, lib = pcall(function() return ffi.load(dir .. 'lib/libuv2.so') end)
if ok and lib then return lib end

error('libuv2 not found')
