local ffi = require 'ffi'
local async = require 'async'
local class = require 'class'
local ctype = require 'ctype'

do
  -- local dir = debug.getinfo(1).source:match('@(.*/)') or ''
  ffi.cdef(io.open('uv2.min.h'):read('*a'))
end

ffi.cdef [[
  void *malloc(size_t size);
  void free(void *ptr);
]]

local libuv = ffi.load('uv')
local libuv2 = ffi.load('uv2')

--------------------------------------------------------------------------------
-- Loop
--------------------------------------------------------------------------------

local Loop = ctype('uv_loop_t')

function Loop:assert(r)
  if tonumber(r) ~= 0 then
    error(self:last_error())
  end
end

function Loop:run()
  return libuv.uv_run(self, libuv.UV_RUN_DEFAULT)
end

function Loop:tcp()
  local tcp = ffi.new('uv_tcp_t')
  libuv.uv_tcp_init(self, tcp)
  return tcp
end

function Loop:fs()
  local fs = ffi.new('uv_fs_t')
  fs.loop = self
  return fs
end

function Loop:timer()
  local timer = ffi.new('uv_timer_t')
  libuv.uv_timer_init(self, timer)
  return timer
end

function Loop:last_error()
  local error = libuv.uv_last_error(self)
  return ffi.string(libuv.uv_err_name(error)) .. ': ' .. ffi.string(libuv.uv_strerror(error))
end

--------------------------------------------------------------------------------
-- mode_atoi
--------------------------------------------------------------------------------

local function octal(s)
  local i = 0
  for c in s:gmatch('.') do
    i = i * 8 + tonumber(c)
  end
  return i
end

do
  assert(octal('0') == 0)
  assert(octal('1') == 1)
  assert(octal('10') == 8)
  assert(octal('11') == 9)
  assert(octal('100') == 64)
  assert(octal('101') == 65)
end

local mode_atoi = setmetatable({}, { __index = function(self, s)
  local i
  if type(s) == 'string' then
    if #s == 3 then
      i = octal(s)
    elseif #s == 9 then
      i = 0
      local function match_char(index, expected_char, n)
        local char = s:sub(index, index)
        if char == expected_char then
          i = i + n
        elseif char ~= '-' then
          error('file modes look like: "755" or "rwxr-xr-x"')
        end
      end
      match_char(1, 'r', 256)
      match_char(2, 'w', 128)
      match_char(3, 'x', 64)
      match_char(4, 'r', 32)
      match_char(5, 'w', 16)
      match_char(6, 'x', 8)
      match_char(7, 'r', 4)
      match_char(8, 'w', 2)
      match_char(9, 'x', 1)
    else
      error('file modes look like: "755" or "rwxr-xr-x"')
    end
  elseif type(s) == 'number' then
    i = s
  else
    error('unexpected mode type: ' .. type(s))
  end
  self[s] = i
  return i
end})

do
  assert(mode_atoi['001'] == 1)
  assert(mode_atoi['007'] == 7)
  assert(mode_atoi['070'] == 7 * 8)
  assert(mode_atoi['700'] == 7 * 64)
  assert(mode_atoi['777'] == 511)

  assert(mode_atoi['--------x'] == 1)
  assert(mode_atoi['-------w-'] == 2)
  assert(mode_atoi['------r--'] == 4)
  assert(mode_atoi['-----x---'] == 8)
  assert(mode_atoi['----w----'] == 16)
  assert(mode_atoi['---r-----'] == 32)
  assert(mode_atoi['--x------'] == 64)
  assert(mode_atoi['-w-------'] == 128)
  assert(mode_atoi['r--------'] == 256)
  assert(mode_atoi['rwxrwxrwx'] == 511)

  assert(mode_atoi[1] == 1)
  assert(mode_atoi[511] == 511)

  do
    local ok, err = pcall(function() return mode_atoi[true] end)
    assert(not ok)
    assert(err:find('unexpected mode type: boolean'))
  end
end

--------------------------------------------------------------------------------
-- flags_atoi
--------------------------------------------------------------------------------

local flags_atoi = setmetatable({}, { __index = function(self, s)
  assert(type(s) == 'number', 'file flags should be "r", "w", "a", "r+", "w+", "a+", or a number')
  self[s] = s
  return s
end})

do
  local O_RDONLY    = 0x0000    -- open for reading only
  local O_WRONLY    = 0x0001    -- open for writing only
  local O_RDWR      = 0x0002    -- open for reading and writing
  local O_NONBLOCK  = 0x0004    -- no delay
  local O_APPEND    = 0x0008    -- set append mode
  local O_SHLOCK    = 0x0010    -- open with shared file lock
  local O_EXLOCK    = 0x0020    -- open with exclusive file lock
  local O_ASYNC     = 0x0040    -- signal pgrp when data ready
  local O_NOFOLLOW  = 0x0100    -- don't follow symlinks
  local O_CREAT     = 0x0200    -- create if nonexistant
  local O_TRUNC     = 0x0400    -- truncate to zero length
  local O_EXCL      = 0x0800    -- error if already exists

  flags_atoi['r'] = O_RDONLY
  flags_atoi['w'] = O_WRONLY + O_CREAT + O_TRUNC
  flags_atoi['a'] = O_WRONLY + O_CREAT + O_APPEND
  flags_atoi['r+'] = O_RDWR
  flags_atoi['w+'] = O_RDWR + O_CREAT + O_TRUNC
  flags_atoi['a+'] = O_RDWR + O_CREAT + O_APPEND
end

--------------------------------------------------------------------------------
-- Fs
--------------------------------------------------------------------------------

local Fs = ctype('uv_fs_t')

Fs.open = async.func(function(yield, callback, self, path, flags, mode)
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

Fs.read = async.func(function(yield, callback, self, file)
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

Fs.close = async.func(function(yield, callback, self, file)
  self.loop:assert(libuv.uv_fs_close(self.loop, self, file, callback))
  yield(self)
  local status = tonumber(self.result)
  if status < 0 then
    error(self.loop:last_error())
  end
  libuv.uv_fs_req_cleanup(self)
end)

-- int uv_fs_unlink(uv_loop_t* loop, uv_fs_t* req, const char* path, uv_fs_cb cb);

Fs.unlink = async.func(function(yield, callback, self, path)
  self.loop:assert(libuv.uv_fs_unlink(self.loop, self, path, callback))
  yield(self)
  local status = tonumber(self.result)
  if status < 0 then
    error(self.loop:last_error())
  end
  libuv.uv_fs_req_cleanup(self)
end)

-- int uv_fs_write(uv_loop_t* loop, uv_fs_t* req, uv_file file, void* buf, size_t length, int64_t offset, uv_fs_cb cb);

Fs.write = async.func(function(yield, callback, self, file, buffer)
  self.loop:assert(libuv.uv_fs_write(self.loop, self, file, ffi.cast('void*', buffer), #buffer, -1, callback))
  yield(self)
  local status = tonumber(self.result)
  if status < 0 then
    error(self.loop:last_error())
  end
  libuv.uv_fs_req_cleanup(self)
end)

-- int uv_fs_mkdir(uv_loop_t* loop, uv_fs_t* req, const char* path, int mode, uv_fs_cb cb);

Fs.mkdir = async.func(function(yield, callback, self, path, mode)
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

Fs.rmdir = async.func(function(yield, callback, self, path)
  self.loop:assert(libuv.uv_fs_rmdir(self.loop, self, path, callback))
  yield(self)
  local status = tonumber(self.result)
  if status < 0 then
    error(self.loop:last_error())
  end
  libuv.uv_fs_req_cleanup(self)
end)

-- int uv_fs_chmod(uv_loop_t* loop, uv_fs_t* req, const char* path, int mode, uv_fs_cb cb);

Fs.chmod = async.func(function(yield, callback, self, path, mode)
  local mode = mode_atoi[mode or '700']
  self.loop:assert(libuv.uv_fs_chmod(self.loop, self, path, mode, callback))
  yield(self)
  local status = tonumber(self.result)
  if status < 0 then
    error(self.loop:last_error())
  end
  libuv.uv_fs_req_cleanup(self)
end)

-- int uv_fs_stat(uv_loop_t* loop, uv_fs_t* req, const char* path, uv_fs_cb cb);

Fs.stat = async.func(function(yield, callback, self, path)
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

Fs.fstat = async.func(function(yield, callback, self, path)
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

Fs.lstat = async.func(function(yield, callback, self, path)
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

--------------------------------------------------------------------------------
-- Stat
--------------------------------------------------------------------------------

local Stat = ctype('uv_statbuf_t')

local S_IFMT		 = octal('0170000')  -- [XSI] type of file mask
local S_IFIFO		 = octal('0010000')  -- [XSI] named pipe (fifo)
local S_IFCHR		 = octal('0020000')  -- [XSI] character special
local S_IFDIR		 = octal('0040000')  -- [XSI] directory
local S_IFBLK		 = octal('0060000')  -- [XSI] block special
local S_IFREG		 = octal('0100000')  -- [XSI] regular
local S_IFLNK		 = octal('0120000')  -- [XSI] symbolic link
local S_IFSOCK	 = octal('0140000')  -- [XSI] socket

function Stat:uid()
  return self.st_uid
end

function Stat:gid()
  return self.st_gid
end

function Stat:size()
  return self.st_size
end

function Stat:mode()
  return bit.band(self.st_mode, bit.bnot(S_IFMT))
end

function Stat:is_dir()
  return bit.band(self.st_mode, S_IFDIR) > 0
end

function Stat:is_fifo()
  return bit.band(self.st_mode, S_IFIFO) > 0
end

do
  local ok, err = pcall(function() return ffi.new('uv_statbuf_t').st_atime end)
  if ok then
    function Stat:atime()         return self.st_atime end
    function Stat:atimensec()     return self.st_atimensec end
    function Stat:mtime()         return self.st_mtime end
    function Stat:mtimensec()     return self.st_mtimensec end
    function Stat:ctime()         return self.st_ctime end
    function Stat:ctimensec()     return self.st_ctimensec end
    function Stat:birthtime()     return self.st_birthtime end
    function Stat:birthtimensec() return self.st_birthtimensec end
  else
    assert(err:find('st_atime'), err)
    function Stat:atime()         return self.st_atimespec.tv_sec end
    function Stat:atimensec()     return self.st_atimespec.tv_nsec end
    function Stat:mtime()         return self.st_mtimespec.tv_sec end
    function Stat:mtimensec()     return self.st_mtimespec.tv_nsec end
    function Stat:ctime()         return self.st_ctimespec.tv_sec end
    function Stat:ctimensec()     return self.st_ctimespec.tv_nsec end
    function Stat:birthtime()     return self.st_birthtimespec.tv_sec end
    function Stat:birthtimensec() return self.st_birthtimespec.tv_nsec end
  end
end

-- dev_t    st_dev;     /* [XSI] ID of device containing file */ \
-- mode_t   st_mode;    /* [XSI] Mode of file (see below) */ \
-- nlink_t    st_nlink;   /* [XSI] Number of hard links */ \
-- __darwin_ino64_t st_ino;   /* [XSI] File serial number */ \
-- uid_t    st_uid;     /* [XSI] User ID of the file */ \
-- gid_t    st_gid;     /* [XSI] Group ID of the file */ \
-- dev_t    st_rdev;    /* [XSI] Device ID */ \

-- -- darwin
-- struct timespec st_atimespec;    /* time of last access */ \
-- struct timespec st_mtimespec;    /* time of last data modification */ \
-- struct timespec st_ctimespec;    /* time of last status change */ \
-- struct timespec st_birthtimespec;  /* time of file creation(birth) */
-- 
-- -- posix
-- time_t   st_atime;   /* [XSI] Time of last access */ \
-- long   st_atimensec;   /* nsec of last access */ \
-- time_t   st_mtime;   /* [XSI] Last data modification time */ \
-- long   st_mtimensec;   /* last data modification nsec */ \
-- time_t   st_ctime;   /* [XSI] Time of last status change */ \
-- long   st_ctimensec;   /* nsec of last status change */ \
-- time_t   st_birthtime;   /*  File creation time(birth)  */ \
-- long   st_birthtimensec; /* nsec of File creation time */

-- off_t    st_size;    /* [XSI] file size, in bytes */ \
-- blkcnt_t st_blocks;    /* [XSI] blocks allocated for file */ \
-- blksize_t  st_blksize;   /* [XSI] optimal blocksize for I/O */ \
-- __uint32_t st_flags;   /* user defined flags for file */ \
-- __uint32_t st_gen;     /* file generation number */ \
-- __int32_t  st_lspare;    /* RESERVED: DO NOT USE! */ \
-- __int64_t  st_qspare[2];   /* RESERVED: DO NOT USE! */ \


--------------------------------------------------------------------------------
-- Timer
--------------------------------------------------------------------------------

local Timer = ctype('uv_timer_t')

function Timer:start(callback, timeout, repeat_time)
  return self.loop:assert(libuv.uv_timer_start(self, callback, timeout or 0, repeat_time or 0))
end

--------------------------------------------------------------------------------
-- Stream
--------------------------------------------------------------------------------

local Stream = ctype('uv_stream_t')

function Stream:accept(client)
  return 0 == tonumber(libuv.uv_accept(self, ffi.cast('uv_stream_t*', client)))
end

--------------------------------------------------------------------------------
-- Tcp
--------------------------------------------------------------------------------

local Tcp = ctype('uv_tcp_t')

function Tcp:bind(ip, port)
  libuv.uv_tcp_bind(self, libuv.uv_ip4_addr(ip, port))
end

Tcp.read = async.func(function(yield, callback, self)
  libuv2.lua_uv_read_start(ffi.cast('uv_stream_t*', self), libuv2.lua_uv_alloc, callback)
  local nread, buf_base, buf_len = yield(self)
  libuv.uv_read_stop(ffi.cast('uv_stream_t*', self))
  return ffi.string(buf_base, nread)
end)

Tcp.write = async.func(function(yield, callback, self, content)
  local req = ffi.new('uv_write_t')
  local buf = ffi.new('uv_buf_t')
  buf.base = ffi.cast('char*', content)
  buf.len = #content
  -- local buf = libuv.uv_buf_init(s, #s)
  self.loop:assert(libuv.uv_write(req, ffi.cast('uv_stream_t*', self), buf, 1, callback))
  local status = yield(req)
  if tonumber(status) ~= 0 then
    -- if not self:is_closing() then
    --   self:close()
    -- end
    error(self.loop:last_error())
    -- if not libuv.uv_is_closing(ffi.cast('uv_handle_t*', self.handle)) then
    --   libuv.uv_close((uv_handle_t*) req->handle, on_close)
    -- end
  end
  -- ffi.C.free(req)
  -- ffi.C.free(buf)
end)

Tcp.listen = async.server(function(callback, self, on_connect)
  self.loop:assert(libuv.uv_listen(ffi.cast('uv_stream_t*', self), 128, callback))
  return self, function(self, status)
    if tonumber(status) >= 0 then
      local client = self.loop:tcp()
      if self:accept(client) then
        on_connect(client)
      else
        client:close()
      end
    end
  end
end)

function Tcp:close()
  libuv.uv_close(ffi.cast('uv_handle_t*', self), nil)
end

--------------------------------------------------------------------------------
-- uv
--------------------------------------------------------------------------------

local uv = {}

function uv.run(main)
  local thread = coroutine.create(main)
  local loop = libuv.uv_default_loop()
  local timer = loop:timer()
  timer:start(function()
    assert(coroutine.resume(thread))
  end)
  loop:run()
end

function uv.fs()
  return libuv.uv_default_loop():fs()
end

function uv.tcp()
  return libuv.uv_default_loop():tcp()
end

return uv
