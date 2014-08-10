local ffi = require 'ffi'

do
  -- local dir = debug.getinfo(1).source:match('@(.*/)') or ''
  local file = assert(io.open('uv.min.h'), 'uv.min.h not find -- try running make')
  ffi.cdef(file:read('*a'))
  file:close()
end

ffi.cdef [[
  void *malloc(size_t size);
  void free(void *ptr);
]]
