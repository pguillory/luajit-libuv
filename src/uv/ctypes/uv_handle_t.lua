local ffi = require 'ffi'
local async = require 'uv/util/async'
local ctype = require 'uv/util/ctype'
local join = require 'uv/util/join'
local libuv = require 'uv/libuv'
local libuv2 = require 'uv/libuv2'
local libc = require 'uv/libc'
local verify = require 'uv/util/verify'

local uv_handle_t = ctype('uv_handle_t')

function uv_handle_t:close()
  -- libuv.uv_unref(self)
  libuv.uv_close(self, async.uv_close_cb)
  async.yield(self)
end

local type_itoa = {
  [libuv.UV_UNKNOWN_HANDLE] = 'unknown_handle',
  [libuv.UV_ASYNC]          = 'async',
  [libuv.UV_CHECK]          = 'check',
  [libuv.UV_FS_EVENT]       = 'fs_event',
  [libuv.UV_FS_POLL]        = 'fs_poll',
  [libuv.UV_HANDLE]         = 'handle',
  [libuv.UV_IDLE]           = 'idle',
  [libuv.UV_NAMED_PIPE]     = 'named_pipe',
  [libuv.UV_POLL]           = 'poll',
  [libuv.UV_PREPARE]        = 'prepare',
  [libuv.UV_PROCESS]        = 'process',
  [libuv.UV_STREAM]         = 'stream',
  [libuv.UV_TCP]            = 'tcp',
  [libuv.UV_TIMER]          = 'timer',
  [libuv.UV_TTY]            = 'tty',
  [libuv.UV_UDP]            = 'udp',
  [libuv.UV_SIGNAL]         = 'signal',
  [libuv.UV_FILE]           = 'file',
}

function uv_handle_t:typestring()
  return type_itoa[tonumber(self.type)] or 'unknown'
end

function uv_handle_t:is_active()
  return 0 ~= libuv.uv_is_active(self)
end

return uv_handle_t
