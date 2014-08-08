require 'strict'
local ffi = require 'ffi'
local class = require 'class'
local ctype = require 'ctype'

do
  -- local dir = debug.getinfo(1).source:match('@(.*/)') or ''
  ffi.cdef(io.open('uv2.min.h'):read('*a'))
end

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

function Loop:timer()
  local timer = ffi.new('uv_timer_t')
  libuv.uv_timer_init(self, timer)
  return timer
end

-- function Loop:fs_open(path, flags, mode, cb)
--   local fs = ffi.new('uv_fs_t')
--   libuv.uv_fs_open(self, fs, argv[1], O_RDONLY, 0, on_open)
--   return server
-- end

--------------------------------------------------------------------------------
-- Fs
--------------------------------------------------------------------------------

local Fs = ctype('uv_fs_t')

function Fs:id()
  return tostring(self):sub(-8)
end

--------------------------------------------------------------------------------
-- Timer
--------------------------------------------------------------------------------

local Timer = ctype('uv_timer_t')

function Timer:start(callback, timeout, repeat_time)
  return self.loop:assert(libuv.uv_timer_start(self, callback, timeout, repeat_time))
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

function Tcp:listen(on_connect)
  self.loop:assert(libuv.uv_listen(ffi.cast('uv_stream_t*', self), 128, on_connect))
end

function Tcp:read(on_read)
  libuv2.lua_uv_read_start(ffi.cast('uv_stream_t*', self), libuv2.lua_uv_alloc, on_read)
end

function Tcp:close()
  libuv.uv_close(ffi.cast('uv_handle_t*', self), nil)
end

--------------------------------------------------------------------------------
-- uv
--------------------------------------------------------------------------------

local uv = {}

uv.default_loop = libuv.uv_default_loop

function uv.run(yield)
  local thread = coroutine.create(yield)
  local loop = uv.default_loop()
  local timer = loop:timer()
  local function run_init()
    assert(coroutine.resume(thread))
  end
  timer:start(run_init, 0, 0)
  loop:run()
end

local File = class(function(descriptor)
  return { descriptor = descriptor }
end)

function File:__tostring()
  return '<File ' .. self.descriptor .. '>'
end

-- UV_EXTERN int uv_fs_read(uv_loop_t* loop, uv_fs_t* req, uv_file file,
--     void* buf, size_t length, int64_t offset, uv_fs_cb cb);

-- local threads = {}

-- local function on_read(req)
--   local thread = assert(threads[req:id()], 'thread not found')
--   local nread = tonumber(req.result)
--   if nread < 0 then
--     return coroutine.resume(thread, nil, 'error opening file: ' .. tonumber(req.errorno))
--   end
--   if nread == 0 then
--     -- EOF
--   end
-- 
--   return coroutine.resume(thread, true, File(descriptor))
-- end
-- 
-- function File:read()
--   local buf = ffi.new('char[?]', 4096)
--   local req = ffi.new('uv_fs_t')
--   threads[req_id] = assert(coroutine.running())
--   uv_fs_read(uv.default_loop(), req, self.descriptor, buf, 4096, -1, on_read);
--   local ok, content = assert(coroutine.yield())
--   threads[req_id] = nil
--   libuv.uv_fs_req_cleanup(req)
--   return content
-- end

-- local function on_open(req)
--   local thread = assert(threads[req:id()], 'thread not found')
--   local descriptor = tonumber(req.result)
--   if descriptor < 0 then
--     return coroutine.resume(thread, nil, 'error opening file: ' .. tonumber(req.errorno))
--   end
--   return coroutine.resume(thread, true, File(descriptor))
-- end
-- 
-- function uv.open(path)
--   local req = ffi.new('uv_fs_t')
--   local req_id = req:id()
--   threads[req_id] = assert(coroutine.running())
--   libuv.uv_fs_open(uv.default_loop(), req, path, 0, 0, on_open)
--   local ok, file = assert(coroutine.yield())
--   threads[req_id] = nil
--   libuv.uv_fs_req_cleanup(req)
--   return file
-- end

function async(before)
  local threads = {}
  local function yield(req)
    local id = req:id()
    threads[id] = assert(coroutine.running())
    coroutine.yield()
  end
  local function callback(req)
    local id = req:id()
    local thread = assert(threads[id], 'thread not found')
    threads[id] = nil
    return assert(coroutine.resume(thread))
  end
  return function(...)
    return before(yield, callback, ...)
  end
end

uv.open = async(function(yield, callback, path)
  local req = ffi.new('uv_fs_t')
  libuv.uv_fs_open(uv.default_loop(), req, path, 0, 0, callback)
  yield(req)
  local descriptor = tonumber(req.result)
  if descriptor < 0 then
    return error('error opening file: ' .. tonumber(req.errorno))
  end
  libuv.uv_fs_req_cleanup(req)
  return File(descriptor)
end)

-- local function on_read(req)
--   local thread = assert(threads[req:id()], 'thread not found')
--   local nread = tonumber(req.result)
--   if nread < 0 then
--     return coroutine.resume(thread, nil, 'error opening file: ' .. tonumber(req.errorno))
--   end
--   if nread == 0 then
--     -- EOF
--   end
-- 
--   return coroutine.resume(thread, true, File(descriptor))
-- end
-- 
-- function File:read()
--   local buf = ffi.new('char[?]', 4096)
--   local req = ffi.new('uv_fs_t')
--   threads[req_id] = assert(coroutine.running())
--   uv_fs_read(uv.default_loop(), req, self.descriptor, buf, 4096, -1, on_read);
--   local ok, content = assert(coroutine.yield())
--   threads[req_id] = nil
--   libuv.uv_fs_req_cleanup(req)
--   return content
-- end

File.read = async(function(yield, callback, self)
  local req = ffi.new('uv_fs_t')
  local buf = ffi.new('char[?]', 4096)
  libuv.uv_fs_read(uv.default_loop(), req, self.descriptor, buf, 4096, -1, callback);
  yield(req)
  local nread = tonumber(req.result)
  if nread < 0 then
    error('error opening file: ' .. tonumber(req.errorno))
  elseif nread == 0 then
    -- EOF
    return ''
  else
    return ffi.string(buf, nread)
  end
end)

--   local req_id = req:id()
--   libuv.uv_fs_open(uv.default_loop(), req, path, 0, 0, on_open)
--   threads[req_id] = assert(coroutine.running())
--   local ok, file = assert(coroutine.yield())
--   threads[req_id] = nil
--   libuv.uv_fs_req_cleanup(req)
--   return file
-- end

return uv
