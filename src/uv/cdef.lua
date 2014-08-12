local ffi = require 'ffi'

ffi.cdef [[
  void *malloc(size_t size);
  void free(void *ptr);
]]
