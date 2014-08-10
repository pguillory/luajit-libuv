require 'uv/cdef'
local ffi = require 'ffi'
local async = require 'async'
local ctype = require 'ctype'
local libuv = require 'uv/libuv'
local libuv2 = require 'uv/libuv2'
local mode_atoi = require 'uv/mode_atoi'
local flags_atoi = require 'uv/flags_atoi'

--------------------------------------------------------------------------------
-- uv_fs_t
--------------------------------------------------------------------------------

local uv_fs_t = ctype('uv_fs_t')

uv_fs_t.open = async.func(function(yield, callback, self, path, flags, mode)
  local flags = flags_atoi[flags or 'r']
  local mode = mode_atoi[mode or '700']
  self.loop:assert(libuv.uv_fs_open(self.loop, self, path, flags, mode, callback))
  yield(self)
  local descriptor = tonumber(self.result)
  if descriptor < 0 then
    error(self.loop:last_error())
  end
  libuv.uv_fs_req_cleanup(self)
  return descriptor
end)

uv_fs_t.read = async.func(function(yield, callback, self, file)
  local buf = ffi.C.malloc(4096)
  self.loop:assert(libuv.uv_fs_read(self.loop, self, file, buf, 4096, -1, callback))
  yield(self)
  local nread = tonumber(self.result)
  if nread < 0 then
    error(self.loop:last_error())
  end
  local chunk = ffi.string(buf, nread)
  ffi.C.free(buf)
  libuv.uv_fs_req_cleanup(self)
  return chunk
end)

uv_fs_t.close = async.func(function(yield, callback, self, file)
  self.loop:assert(libuv.uv_fs_close(self.loop, self, file, callback))
  yield(self)
  local status = tonumber(self.result)
  if status < 0 then
    error(self.loop:last_error())
  end
  libuv.uv_fs_req_cleanup(self)
end)

-- int uv_fs_unlink(uv_loop_t* loop, uv_fs_t* req, const char* path, uv_fs_cb cb);

uv_fs_t.unlink = async.func(function(yield, callback, self, path)
  self.loop:assert(libuv.uv_fs_unlink(self.loop, self, path, callback))
  yield(self)
  local status = tonumber(self.result)
  if status < 0 then
    error(self.loop:last_error())
  end
  libuv.uv_fs_req_cleanup(self)
end)

-- int uv_fs_write(uv_loop_t* loop, uv_fs_t* req, uv_file file, void* buf, size_t length, int64_t offset, uv_fs_cb cb);

uv_fs_t.write = async.func(function(yield, callback, self, file, buffer)
  self.loop:assert(libuv.uv_fs_write(self.loop, self, file, ffi.cast('void*', buffer), #buffer, -1, callback))
  yield(self)
  local status = tonumber(self.result)
  if status < 0 then
    error(self.loop:last_error())
  end
  libuv.uv_fs_req_cleanup(self)
end)

-- int uv_fs_mkdir(uv_loop_t* loop, uv_fs_t* req, const char* path, int mode, uv_fs_cb cb);

uv_fs_t.mkdir = async.func(function(yield, callback, self, path, mode)
  local mode = mode_atoi[mode or '700']
  assert(self.loop, 'no loop!')
  self.loop:assert(libuv.uv_fs_mkdir(self.loop, self, path, mode, callback))
  yield(self)
  local status = tonumber(self.result)
  if status < 0 then
    error(self.loop:last_error())
  end
  libuv.uv_fs_req_cleanup(self)
end)

-- int uv_fs_rmdir(uv_loop_t* loop, uv_fs_t* req, const char* path, uv_fs_cb cb);

uv_fs_t.rmdir = async.func(function(yield, callback, self, path)
  self.loop:assert(libuv.uv_fs_rmdir(self.loop, self, path, callback))
  yield(self)
  local status = tonumber(self.result)
  if status < 0 then
    error(self.loop:last_error())
  end
  libuv.uv_fs_req_cleanup(self)
end)

-- int uv_fs_chmod(uv_loop_t* loop, uv_fs_t* req, const char* path, int mode, uv_fs_cb cb);

uv_fs_t.chmod = async.func(function(yield, callback, self, path, mode)
  local mode = mode_atoi[mode or '700']
  self.loop:assert(libuv.uv_fs_chmod(self.loop, self, path, mode, callback))
  yield(self)
  local status = tonumber(self.result)
  if status < 0 then
    error(self.loop:last_error())
  end
  libuv.uv_fs_req_cleanup(self)
end)

-- int uv_fs_fchmod(uv_loop_t* loop, uv_fs_t* req, uv_file file, int mode, uv_fs_cb cb);

uv_fs_t.fchmod = async.func(function(yield, callback, self, file, mode)
  self.loop:assert(libuv.uv_fs_fchmod(self.loop, self, file, mode, callback))
  yield(self)
  local status = tonumber(self.result)
  if status < 0 then
    error(self.loop:last_error())
  end
  libuv.uv_fs_req_cleanup(self)
end)

-- int uv_fs_chown(uv_loop_t* loop, uv_fs_t* req, const char* path, uv_uid_t uid, uv_gid_t gid, uv_fs_cb cb);

uv_fs_t.chown = async.func(function(yield, callback, self, path, uid, gid)
  self.loop:assert(libuv.uv_fs_chown(self.loop, self, path, uid, gid, callback))
  yield(self)
  local status = tonumber(self.result)
  if status < 0 then
    error(self.loop:last_error())
  end
  libuv.uv_fs_req_cleanup(self)
end)

-- int uv_fs_fchown(uv_loop_t* loop, uv_fs_t* req, uv_file file, uv_uid_t uid, uv_gid_t gid, uv_fs_cb cb);

uv_fs_t.fchown = async.func(function(yield, callback, self, file, uid, gid)
  self.loop:assert(libuv.uv_fs_fchown(self.loop, self, file, uid, gid, callback))
  yield(self)
  local status = tonumber(self.result)
  if status < 0 then
    error(self.loop:last_error())
  end
  libuv.uv_fs_req_cleanup(self)
end)

-- int uv_fs_stat(uv_loop_t* loop, uv_fs_t* req, const char* path, uv_fs_cb cb);

uv_fs_t.stat = async.func(function(yield, callback, self, path)
  self.loop:assert(libuv.uv_fs_stat(self.loop, self, path, callback))
  yield(self)
  local status = tonumber(self.result)
  if status < 0 then
    error(self.loop:last_error())
  end
  local stat = ffi.cast('uv_statbuf_t*', self.ptr)
  libuv.uv_fs_req_cleanup(self)
  return stat
end)

-- int uv_fs_fstat(uv_loop_t* loop, uv_fs_t* req, uv_file file, uv_fs_cb cb);

uv_fs_t.fstat = async.func(function(yield, callback, self, path)
  self.loop:assert(libuv.uv_fs_fstat(self.loop, self, path, callback))
  yield(self)
  local status = tonumber(self.result)
  if status < 0 then
    error(self.loop:last_error())
  end
  local stat = ffi.cast('uv_statbuf_t*', self.ptr)
  libuv.uv_fs_req_cleanup(self)
  return stat
end)

-- int uv_fs_lstat(uv_loop_t* loop, uv_fs_t* req, const char* path, uv_fs_cb cb);

uv_fs_t.lstat = async.func(function(yield, callback, self, path)
  self.loop:assert(libuv.uv_fs_lstat(self.loop, self, path, callback))
  yield(self)
  local status = tonumber(self.result)
  if status < 0 then
    error(self.loop:last_error())
  end
  local stat = ffi.cast('uv_statbuf_t*', self.ptr)
  libuv.uv_fs_req_cleanup(self)
  return stat
end)

-- int uv_fs_rename(uv_loop_t* loop, uv_fs_t* req, const char* path, const char* new_path, uv_fs_cb cb);

uv_fs_t.rename = async.func(function(yield, callback, self, path, new_path)
  self.loop:assert(libuv.uv_fs_rename(self.loop, self, path, new_path, callback))
  yield(self)
  local status = tonumber(self.result)
  if status < 0 then
    error(self.loop:last_error())
  end
  libuv.uv_fs_req_cleanup(self)
end)

-- int uv_fs_link(uv_loop_t* loop, uv_fs_t* req, const char* path, const char* new_path, uv_fs_cb cb);

uv_fs_t.link = async.func(function(yield, callback, self, path, new_path)
  self.loop:assert(libuv.uv_fs_link(self.loop, self, path, new_path, callback))
  yield(self)
  local status = tonumber(self.result)
  if status < 0 then
    error(self.loop:last_error())
  end
  libuv.uv_fs_req_cleanup(self)
end)

-- int uv_fs_symlink(uv_loop_t* loop, uv_fs_t* req, const char* path, const char* new_path, int flags, uv_fs_cb cb);

uv_fs_t.symlink = async.func(function(yield, callback, self, path, new_path, flags)
  local flags = flags or 0
  self.loop:assert(libuv.uv_fs_symlink(self.loop, self, path, new_path, flags, callback))
  yield(self)
  local status = tonumber(self.result)
  if status < 0 then
    error(self.loop:last_error())
  end
  libuv.uv_fs_req_cleanup(self)
end)

-- int uv_fs_readlink(uv_loop_t* loop, uv_fs_t* req, const char* path, uv_fs_cb cb);

uv_fs_t.readlink = async.func(function(yield, callback, self, path)
  self.loop:assert(libuv.uv_fs_readlink(self.loop, self, path, callback))
  yield(self)
  local status = tonumber(self.result)
  if status < 0 then
    error(self.loop:last_error())
  end
  local path = ffi.string(self.ptr)
  libuv.uv_fs_req_cleanup(self)
  return path
end)

-- int uv_fs_fsync(uv_loop_t* loop, uv_fs_t* req, uv_file file, uv_fs_cb cb);

uv_fs_t.fsync = async.func(function(yield, callback, self, file)
  self.loop:assert(libuv.uv_fs_fsync(self.loop, self, file, callback))
  yield(self)
  local status = tonumber(self.result)
  if status < 0 then
    error(self.loop:last_error())
  end
  libuv.uv_fs_req_cleanup(self)
end)

return uv_fs_t
