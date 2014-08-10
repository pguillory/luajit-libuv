local ffi = require 'ffi'

do
  -- local dir = debug.getinfo(1).source:match('@(.*/)') or ''
  ffi.cdef(io.open('uv2.min.h'):read('*a'))
end

ffi.cdef [[
  void *malloc(size_t size);
  void free(void *ptr);
]]
