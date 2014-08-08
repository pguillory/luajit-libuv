require 'strict'
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
    error(libuv.uv_err_name(libuv.uv_last_error(self)))
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

--------------------------------------------------------------------------------
-- mode_atoi
--------------------------------------------------------------------------------

local mode_atoi = setmetatable({}, { __index = function(self, s)
  local i
  if type(s) == 'string' then
    if #s == 3 then
      i = 0
      local function digit_value(index, value)
        local digit = tonumber(s:sub(index, index))
        if digit < 0 or digit > 7 then
          error('file modes look like: "755" or "rwxr-xr-x"')
        end
        i = i + digit * value
      end
      digit_value(1, 64)
      digit_value(2, 8)
      digit_value(3, 1)
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
  assert((7 * 64) + (5 * 8) + (5 * 1) == 493)
  assert(mode_atoi['755'] == 493)
  assert(mode_atoi['rwxr-xr-x'] == 493)
  local ok, err = pcall(function()
    return mode_atoi[true]
  end)
  assert(not ok)
  assert(err:find('unexpected mode type: boolean'))
end

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
  flags_atoi['w'] = O_WRONLY + O_CREAT
  flags_atoi['a'] = O_RDWR
  flags_atoi['r+'] = O_RDONLY
  flags_atoi['w+'] = O_WRONLY
  flags_atoi['a+'] = O_RDWR
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
    return error('error opening file: ' .. tonumber(self.errorno))
  end
  -- print('opened file ', descriptor)
  -- libuv.uv_fs_req_cleanup(self)
  -- return File(descriptor)
  return descriptor
end)

Fs.read = async.func(function(yield, callback, self, file)
  local buf = ffi.C.malloc(4096)
  self.loop:assert(libuv.uv_fs_read(self.loop, self, file, buf, 4096, -1, callback))
  yield(self)
  local nread = tonumber(self.result)
  if nread < 0 then
    error('error reading file: ' .. tonumber(self.errorno))
  end
  ffi.C.free(buf)
  return ffi.string(buf, nread)
end)

Fs.close = async.func(function(yield, callback, self, file)
  self.loop:assert(libuv.uv_fs_close(self.loop, self, self.result, callback))
  yield(self)
  local status = tonumber(self.result)
  if status < 0 then
    error('error closing file: ' .. tonumber(self.errorno))
  end
end)

-- int uv_fs_unlink(uv_loop_t* loop, uv_fs_t* req, const char* path, uv_fs_cb cb);

Fs.unlink = async.func(function(yield, callback, self, path)
  self.loop:assert(libuv.uv_fs_unlink(self.loop, self, path, callback))
  yield(self)
  local status = tonumber(self.result)
  if status < 0 then
    error('error unlinking file: ' .. tonumber(self.errorno))
  end
end)

-- int uv_fs_write(uv_loop_t* loop, uv_fs_t* req, uv_file file, void* buf, size_t length, int64_t offset, uv_fs_cb cb);

Fs.write = async.func(function(yield, callback, self, buffer)
  self.loop:assert(libuv.uv_fs_write(self.loop, self, self.result, buffer, #buffer, -1, callback))
  yield(self)
  local status = tonumber(self.result)
  if status < 0 then
    error('error writing file: ' .. tonumber(self.errorno))
  end
end)

-- int uv_fs_mkdir(uv_loop_t* loop, uv_fs_t* req, const char* path, int mode, uv_fs_cb cb);

Fs.mkdir = async.func(function(yield, callback, self, path, mode)
  local mode = mode_atoi[mode or '700']
  self.loop:assert(libuv.uv_fs_mkdir(self.loop, self, path, mode, callback))
  yield(self)
  local status = tonumber(self.result)
  if status < 0 then
    error('error making directory: ' .. tonumber(self.errorno))
  end
end)

-- int uv_fs_rmdir(uv_loop_t* loop, uv_fs_t* req, const char* path, uv_fs_cb cb);

Fs.rmdir = async.func(function(yield, callback, self, path)
  self.loop:assert(libuv.uv_fs_rmdir(self.loop, self, path, callback))
  yield(self)
  local status = tonumber(self.result)
  if status < 0 then
    error('error removing directory: ' .. tonumber(self.errorno))
  end
end)




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
  assert(0 == tonumber(libuv.uv_write(req, ffi.cast('uv_stream_t*', self), buf, 1, callback)))
  local status = yield(req)
  if tonumber(status) ~= 0 then
    print('write error: ', libuv.uv_err_name(status), libuv.uv_strerror(status))
    if not self:is_closing() then
      self:close()
    end
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
