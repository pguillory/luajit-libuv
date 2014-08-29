local ffi = require 'ffi'
local ctype = require 'uv/util/ctype'
local libuv = require 'uv/libuv'
local libuv2 = require 'uv/libuv2'
local libc = require 'uv/libc'
local uv_buf_t = require 'uv/ctypes/uv_buf_t'
local uv_signal_t = require 'uv/ctypes/uv_signal_t'
local join = require 'uv/util/join'

local signals = {
  kill  = libuv2.uv2_sigkill(),
  int   = libuv2.uv2_sigint(),
  hup   = libuv2.uv2_sighup(),
  winch = libuv2.uv2_sigwinch(),
}

local signum_atoi = {}
for k, v in pairs(signals) do
  signum_atoi[k] = v
  signum_atoi['SIG' .. k:upper()] = v
  signum_atoi[v] = v
end

local process = {}

function process.pid()
  return libc.getpid();
end

function process.on(signum, callback)
  local signum = signum_atoi[signum]
  local sig = uv_signal_t()
  join(coroutine.create(function()
    sig:start(signum, callback)
  end))
  return sig
end

function process.kill(pid, signum)
  local signum = signum_atoi[signum or 'kill']
  libuv.uv_default_loop():assert(libuv.uv_kill(pid, signum))
end

function process.path()
  local buf = uv_buf_t()
  local status = libuv2.uv2_exepath(buf)
  assert(status == 0)
  local result = ffi.string(buf.base, buf.len)
  buf:free()
  return result
end

return process
