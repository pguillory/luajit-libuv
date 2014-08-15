require 'uv/cdef'
local ffi = require 'ffi'
local async = require 'uv/async'
local async = require 'uv/async'
local ctype = require 'uv/ctype'
local libuv = require 'uv/libuv'
local uv_buf_t = require 'uv/uv_buf_t'

--------------------------------------------------------------------------------
-- uv_fs_t
--------------------------------------------------------------------------------

local uv_fs_t = ctype('uv_fs_t', function(loop)
  local self = ffi.cast('uv_fs_t*', ffi.C.malloc(ffi.sizeof('uv_fs_t')))
  self.loop = loop or libuv.uv_default_loop()
  return self
end)

function uv_fs_t:open(path, flags, mode)
  self.loop:assert(libuv.uv_fs_open(self.loop, self, path, flags, mode, async.uv_fs_cb))
  async.yield(self)
  local descriptor = tonumber(self.result)
  if descriptor < 0 then
    error(ffi.string(libuv.uv_strerror(self.result)))
  end
  libuv.uv_fs_req_cleanup(self)
  return descriptor
end

function uv_fs_t:read(file)
  local buf = uv_buf_t()
  self.loop:assert(libuv.uv_fs_read(self.loop, self, file, buf, 1, -1, async.uv_fs_cb))
  async.yield(self)
  local nread = tonumber(self.result)
  if nread < 0 then
    error(ffi.string(libuv.uv_strerror(self.result)))
  end
  local chunk = ffi.string(buf.base, nread)
  buf:free()
  libuv.uv_fs_req_cleanup(self)
  return chunk
end

function uv_fs_t:close(file)
  self.loop:assert(libuv.uv_fs_close(self.loop, self, file, async.uv_fs_cb))
  async.yield(self)
  local status = tonumber(self.result)
  if status < 0 then
    error(ffi.string(libuv.uv_strerror(self.result)))
  end
  libuv.uv_fs_req_cleanup(self)
end

function uv_fs_t:unlink(path)
  self.loop:assert(libuv.uv_fs_unlink(self.loop, self, path, async.uv_fs_cb))
  async.yield(self)
  local status = tonumber(self.result)
  if status < 0 then
    error(ffi.string(libuv.uv_strerror(self.result)))
  end
  libuv.uv_fs_req_cleanup(self)
end

function uv_fs_t:write(file, buffer)
  local buf = uv_buf_t(buffer, #buffer)
  self.loop:assert(libuv.uv_fs_write(self.loop, self, file, buf, 1, -1, async.uv_fs_cb))
  async.yield(self)
  buf:free()
  local status = tonumber(self.result)
  if status < 0 then
    error(ffi.string(libuv.uv_strerror(self.result)))
  end
  libuv.uv_fs_req_cleanup(self)
end

function uv_fs_t:mkdir(path, mode)
  self.loop:assert(libuv.uv_fs_mkdir(self.loop, self, path, mode, async.uv_fs_cb))
  async.yield(self)
  local status = tonumber(self.result)
  if status < 0 then
    error(ffi.string(libuv.uv_strerror(self.result)))
  end
  libuv.uv_fs_req_cleanup(self)
end

function uv_fs_t:rmdir(path)
  self.loop:assert(libuv.uv_fs_rmdir(self.loop, self, path, async.uv_fs_cb))
  async.yield(self)
  local status = tonumber(self.result)
  if status < 0 then
    error(ffi.string(libuv.uv_strerror(self.result)))
  end
  libuv.uv_fs_req_cleanup(self)
end

function uv_fs_t:chmod(path, mode)
  self.loop:assert(libuv.uv_fs_chmod(self.loop, self, path, mode, async.uv_fs_cb))
  async.yield(self)
  local status = tonumber(self.result)
  if status < 0 then
    error(ffi.string(libuv.uv_strerror(self.result)))
  end
  libuv.uv_fs_req_cleanup(self)
end

function uv_fs_t:fchmod(file, mode)
  self.loop:assert(libuv.uv_fs_fchmod(self.loop, self, file, mode, async.uv_fs_cb))
  async.yield(self)
  local status = tonumber(self.result)
  if status < 0 then
    error(ffi.string(libuv.uv_strerror(self.result)))
  end
  libuv.uv_fs_req_cleanup(self)
end

function uv_fs_t:chown(path, uid, gid)
  self.loop:assert(libuv.uv_fs_chown(self.loop, self, path, uid, gid, async.uv_fs_cb))
  async.yield(self)
  local status = tonumber(self.result)
  if status < 0 then
    error(ffi.string(libuv.uv_strerror(self.result)))
  end
  libuv.uv_fs_req_cleanup(self)
end

function uv_fs_t:fchown(file, uid, gid)
  self.loop:assert(libuv.uv_fs_fchown(self.loop, self, file, uid, gid, async.uv_fs_cb))
  async.yield(self)
  local status = tonumber(self.result)
  if status < 0 then
    error(ffi.string(libuv.uv_strerror(self.result)))
  end
  libuv.uv_fs_req_cleanup(self)
end

function uv_fs_t:stat(path)
  self.loop:assert(libuv.uv_fs_stat(self.loop, self, path, async.uv_fs_cb))
  async.yield(self)
  local status = tonumber(self.result)
  if status < 0 then
    error(ffi.string(libuv.uv_strerror(self.result)))
  end
  local stat = ffi.cast('uv_stat_t*', self.ptr)
  libuv.uv_fs_req_cleanup(self)
  return stat
end

function uv_fs_t:fstat(path)
  self.loop:assert(libuv.uv_fs_fstat(self.loop, self, path, async.uv_fs_cb))
  async.yield(self)
  local status = tonumber(self.result)
  if status < 0 then
    error(ffi.string(libuv.uv_strerror(self.result)))
  end
  local stat = ffi.cast('uv_stat_t*', self.ptr)
  libuv.uv_fs_req_cleanup(self)
  return stat
end

function uv_fs_t:lstat(path)
  self.loop:assert(libuv.uv_fs_lstat(self.loop, self, path, async.uv_fs_cb))
  async.yield(self)
  local status = tonumber(self.result)
  if status < 0 then
    error(ffi.string(libuv.uv_strerror(self.result)))
  end
  local stat = ffi.cast('uv_stat_t*', self.ptr)
  libuv.uv_fs_req_cleanup(self)
  return stat
end

function uv_fs_t:rename(path, new_path)
  self.loop:assert(libuv.uv_fs_rename(self.loop, self, path, new_path, async.uv_fs_cb))
  async.yield(self)
  local status = tonumber(self.result)
  if status < 0 then
    error(ffi.string(libuv.uv_strerror(self.result)))
  end
  libuv.uv_fs_req_cleanup(self)
end

function uv_fs_t:link(path, new_path)
  self.loop:assert(libuv.uv_fs_link(self.loop, self, path, new_path, async.uv_fs_cb))
  async.yield(self)
  local status = tonumber(self.result)
  if status < 0 then
    error(ffi.string(libuv.uv_strerror(self.result)))
  end
  libuv.uv_fs_req_cleanup(self)
end

function uv_fs_t:symlink(path, new_path, flags)
  local flags = flags or 0
  self.loop:assert(libuv.uv_fs_symlink(self.loop, self, path, new_path, flags, async.uv_fs_cb))
  async.yield(self)
  local status = tonumber(self.result)
  if status < 0 then
    error(ffi.string(libuv.uv_strerror(self.result)))
  end
  libuv.uv_fs_req_cleanup(self)
end

function uv_fs_t:readlink(path)
  self.loop:assert(libuv.uv_fs_readlink(self.loop, self, path, async.uv_fs_cb))
  async.yield(self)
  local status = tonumber(self.result)
  if status < 0 then
    error(ffi.string(libuv.uv_strerror(self.result)))
  end
  local path = ffi.string(self.ptr)
  libuv.uv_fs_req_cleanup(self)
  return path
end

function uv_fs_t:fsync(file)
  self.loop:assert(libuv.uv_fs_fsync(self.loop, self, file, async.uv_fs_cb))
  async.yield(self)
  local status = tonumber(self.result)
  if status < 0 then
    error(ffi.string(libuv.uv_strerror(self.result)))
  end
  libuv.uv_fs_req_cleanup(self)
end

return uv_fs_t
