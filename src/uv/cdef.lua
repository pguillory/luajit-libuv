local ffi = require 'ffi'

local function readfile(path)
  local file = assert(io.open(path))
  local body = file:read('*a')
  file:close()
  return body
end

-- local dir = debug.getinfo(1).source:match('@(.*/)') or ''
ffi.cdef(readfile('uv.min.h'))
ffi.cdef(readfile('http_parser.min.h'))

ffi.cdef [[
  void *malloc(size_t size);
  void free(void *ptr);
]]
