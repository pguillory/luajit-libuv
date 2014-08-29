local ffi = require 'ffi'

ffi.cdef [[
  void *malloc(size_t size);
  void free(void *ptr);
  uint16_t ntohs(uint16_t netshort);
  mode_t umask(mode_t mask);
  uid_t getuid(void);
  gid_t getgid(void);
  pid_t getpid(void);
]]

return ffi.C
