require 'uv/ctypes/init'
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

function process.usage()
  local usage = ffi.new('uv_rusage_t')
  libuv.uv_default_loop():assert(libuv.uv_getrusage(usage))
  local result = {
    utime = usage.ru_utime.tv_usec,
    stime = usage.ru_stime.tv_usec,
    maxrss = usage.ru_maxrss,
    ixrss = usage.ru_ixrss,
    idrss = usage.ru_idrss,
    isrss = usage.ru_isrss,
    minflt = usage.ru_minflt,
    majflt = usage.ru_majflt,
    nswap = usage.ru_nswap,
    inblock = usage.ru_inblock,
    oublock = usage.ru_oublock,
    msgsnd = usage.ru_msgsnd,
    msgrcv = usage.ru_msgrcv,
    nsignals = usage.ru_nsignals,
    nvcsw = usage.ru_nvcsw,
    nivcsw = usage.ru_nivcsw,
  }
  return result
end

return process
