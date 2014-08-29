local ffi = require 'ffi'
local ctype = require 'uv/util/ctype'
local libuv = require 'uv/libuv'
local libuv2 = require 'uv/libuv2'
local libc = require 'uv/libc'
local uv_signal_t = require 'uv/ctypes/uv_signal_t'
local join = require 'uv/util/join'

local signum_atoi = {
  ['SIGINT']   = libuv2.uv2_sigint(),
  ['SIGHUP']   = libuv2.uv2_sighup(),
  ['SIGWINCH'] = libuv2.uv2_sigwinch(),
  ['int']   = libuv2.uv2_sigint(),
  ['hup']   = libuv2.uv2_sighup(),
  ['winch'] = libuv2.uv2_sigwinch(),
  [libuv2.uv2_sigint()]   = libuv2.uv2_sigint(),
  [libuv2.uv2_sighup()]   = libuv2.uv2_sighup(),
  [libuv2.uv2_sigwinch()] = libuv2.uv2_sigwinch(),
}

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
  local signum = signum_atoi[signum]
  libuv.uv_default_loop():assert(libuv.uv_kill(pid, signum))
end

return process
