local ffi = require 'ffi'
local async = require 'uv/util/async'
local ctype = require 'uv/util/ctype'
local libuv = require 'uv/libuv'
local libuv2 = require 'uv/libuv2'
local libc = require 'uv/libc'
local uv_buf_t = require 'uv/ctypes/uv_buf_t'
local uv_loop_t = require 'uv/ctypes/uv_loop_t'
local errno = require 'uv/util/errno'
local verify = require 'uv/util/verify'

--------------------------------------------------------------------------------
-- uv_fs_t
--------------------------------------------------------------------------------

local uv_fs_t = ctype('uv_fs_t', function(loop)
  local self = ffi.cast('uv_fs_t*', libc.malloc(ffi.sizeof('uv_fs_t')))
  self.loop = loop or libuv.uv_default_loop()
  return self
end)

function uv_fs_t:open(path, flags, mode)
  verify(libuv2.uv2_fs_open(self.loop, self, path, flags, mode, async.uv_fs_cb))
  async.yield(self)
  local descriptor = tonumber(self.result)
  if descriptor < 0 then
    error(errno[tonumber(self.result)])
  end
  libuv.uv_fs_req_cleanup(self)
  return descriptor
end

function uv_fs_t:read(file)
  local buf = uv_buf_t()
  verify(libuv.uv_fs_read(self.loop, self, file, buf, 1, -1, async.uv_fs_cb))
  async.yield(self)
  local nread = tonumber(self.result)
  if nread < 0 then
    error(errno[tonumber(self.result)])
  end
  local chunk = ffi.string(buf.base, nread)
  buf:free()
  libuv.uv_fs_req_cleanup(self)
  return chunk
end

function uv_fs_t:close(file)
  verify(libuv.uv_fs_close(self.loop, self, file, async.uv_fs_cb))
  async.yield(self)
  local status = tonumber(self.result)
  if status < 0 then
    error(errno[tonumber(self.result)])
  end
  libuv.uv_fs_req_cleanup(self)
end

function uv_fs_t:unlink(path)
  verify(libuv.uv_fs_unlink(self.loop, self, path, async.uv_fs_cb))
  async.yield(self)
  local status = tonumber(self.result)
  if status < 0 then
    error(errno[tonumber(self.result)])
  end
  libuv.uv_fs_req_cleanup(self)
end

function uv_fs_t:write(file, buffer)
  local buf = uv_buf_t(buffer, #buffer)
  verify(libuv.uv_fs_write(self.loop, self, file, buf, 1, -1, async.uv_fs_cb))
  async.yield(self)
  buf:free()
  local status = tonumber(self.result)
  if status < 0 then
    error(errno[tonumber(self.result)])
  end
  libuv.uv_fs_req_cleanup(self)
end

function uv_fs_t:mkdir(path, mode)
  verify(libuv.uv_fs_mkdir(self.loop, self, path, mode, async.uv_fs_cb))
  async.yield(self)
  local status = tonumber(self.result)
  if status < 0 then
    error(errno[tonumber(self.result)])
  end
  libuv.uv_fs_req_cleanup(self)
end

function uv_fs_t:rmdir(path)
  verify(libuv.uv_fs_rmdir(self.loop, self, path, async.uv_fs_cb))
  async.yield(self)
  local status = tonumber(self.result)
  if status < 0 then
    error(errno[tonumber(self.result)])
  end
  libuv.uv_fs_req_cleanup(self)
end

function uv_fs_t:chmod(path, mode)
  verify(libuv.uv_fs_chmod(self.loop, self, path, mode, async.uv_fs_cb))
  async.yield(self)
  local status = tonumber(self.result)
  if status < 0 then
    error(errno[tonumber(self.result)])
  end
  libuv.uv_fs_req_cleanup(self)
end

function uv_fs_t:fchmod(file, mode)
  verify(libuv.uv_fs_fchmod(self.loop, self, file, mode, async.uv_fs_cb))
  async.yield(self)
  local status = tonumber(self.result)
  if status < 0 then
    error(errno[tonumber(self.result)])
  end
  libuv.uv_fs_req_cleanup(self)
end

function uv_fs_t:chown(path, uid, gid)
  verify(libuv.uv_fs_chown(self.loop, self, path, uid, gid, async.uv_fs_cb))
  async.yield(self)
  local status = tonumber(self.result)
  if status < 0 then
    error(errno[tonumber(self.result)])
  end
  libuv.uv_fs_req_cleanup(self)
end

function uv_fs_t:fchown(file, uid, gid)
  verify(libuv.uv_fs_fchown(self.loop, self, file, uid, gid, async.uv_fs_cb))
  async.yield(self)
  local status = tonumber(self.result)
  if status < 0 then
    error(errno[tonumber(self.result)])
  end
  libuv.uv_fs_req_cleanup(self)
end

function uv_fs_t:stat(path)
  verify(libuv.uv_fs_stat(self.loop, self, path, async.uv_fs_cb))
  async.yield(self)
  local status = tonumber(self.result)
  if status < 0 then
    error(errno[tonumber(self.result)])
  end
  local stat = ffi.cast('uv_stat_t*', self.ptr)
  libuv.uv_fs_req_cleanup(self)
  return stat
end

function uv_fs_t:fstat(path)
  verify(libuv.uv_fs_fstat(self.loop, self, path, async.uv_fs_cb))
  async.yield(self)
  local status = tonumber(self.result)
  if status < 0 then
    error(errno[tonumber(self.result)])
  end
  local stat = ffi.cast('uv_stat_t*', self.ptr)
  libuv.uv_fs_req_cleanup(self)
  return stat
end

function uv_fs_t:lstat(path)
  verify(libuv.uv_fs_lstat(self.loop, self, path, async.uv_fs_cb))
  async.yield(self)
  local status = tonumber(self.result)
  if status < 0 then
    error(errno[tonumber(self.result)])
  end
  local stat = ffi.cast('uv_stat_t*', self.ptr)
  libuv.uv_fs_req_cleanup(self)
  return stat
end

function uv_fs_t:rename(path, new_path)
  verify(libuv.uv_fs_rename(self.loop, self, path, new_path, async.uv_fs_cb))
  async.yield(self)
  local status = tonumber(self.result)
  if status < 0 then
    error(errno[tonumber(self.result)])
  end
  libuv.uv_fs_req_cleanup(self)
end

function uv_fs_t:link(path, new_path)
  verify(libuv.uv_fs_link(self.loop, self, path, new_path, async.uv_fs_cb))
  async.yield(self)
  local status = tonumber(self.result)
  if status < 0 then
    error(errno[tonumber(self.result)])
  end
  libuv.uv_fs_req_cleanup(self)
end

function uv_fs_t:symlink(path, new_path, flags)
  local flags = flags or 0
  verify(libuv.uv_fs_symlink(self.loop, self, path, new_path, flags, async.uv_fs_cb))
  async.yield(self)
  local status = tonumber(self.result)
  if status < 0 then
    error(errno[tonumber(self.result)])
  end
  libuv.uv_fs_req_cleanup(self)
end

function uv_fs_t:readlink(path)
  verify(libuv.uv_fs_readlink(self.loop, self, path, async.uv_fs_cb))
  async.yield(self)
  local status = tonumber(self.result)
  if status < 0 then
    error(errno[tonumber(self.result)])
  end
  local path = ffi.string(self.ptr)
  libuv.uv_fs_req_cleanup(self)
  return path
end

function uv_fs_t:fsync(file)
  verify(libuv.uv_fs_fsync(self.loop, self, file, async.uv_fs_cb))
  async.yield(self)
  local status = tonumber(self.result)
  if status < 0 then
    error(errno[tonumber(self.result)])
  end
  libuv.uv_fs_req_cleanup(self)
end

local function cstrings(cstrings, count)
  cstrings = ffi.cast('char*', cstrings)
  local t = {}
  for i = 1, count do
    local s = ffi.string(cstrings)
    cstrings = cstrings + #s + 1
    t[i] = s
  end
  return t
end

function uv_fs_t:readdir(path, flags)
  verify(libuv.uv_fs_readdir(self.loop, self, path, flags, async.uv_fs_cb))
  async.yield(self)
  local status = tonumber(self.result)
  if status < 0 then
    error(errno[tonumber(self.result)])
  end
  local filenames = cstrings(self.ptr, status)
  libuv.uv_fs_req_cleanup(self)
  return filenames
end

return uv_fs_t
