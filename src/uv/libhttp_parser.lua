local ffi = require 'ffi'

local dir = debug.getinfo(1).source:match('@(.*/)') or '.'

do
  local file = io.open(dir .. 'lib/libhttp_parser.min.h')
  if not file then
    error('libhttp_parser.min.h not found')
  end
  local header = file:read('*a')
  ffi.cdef(header:match('typedef struct http_parser.*'))
  file:close()
end

local ok, lib = pcall(function() return ffi.load(dir .. 'lib/libhttp_parser.dylib') end)
if ok then return lib end

local ok, lib = pcall(function() return ffi.load(dir .. 'lib/libhttp_parser.so') end)
if ok then return lib end

assert('libhttp_parser not found')
