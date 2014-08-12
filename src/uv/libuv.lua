local ffi = require 'ffi'

local dir = debug.getinfo(1).source:match('@(.*/)') or ''

do
  local file = io.open(dir .. 'libuv.min.h')
  if not file then
    error('libuv.min.h not found')
  end
  local header = file:read('*a')
  ffi.cdef(header)
  file:close()
end

local ok, lib = pcall(function() return ffi.load(dir .. 'libuv.dylib') end)
if ok then return lib end

local ok, lib = pcall(function() return ffi.load(dir .. 'libuv.so') end)
if ok then return lib end

assert('libuv not found')
