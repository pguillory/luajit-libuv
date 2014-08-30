require 'uv/ctypes/init'
local ffi = require 'ffi'
local async = require 'uv/util/async'
local ctype = require 'uv/util/ctype'
local libuv = require 'uv/libuv'
local libuv2 = require 'uv/libuv2'
local libc = require 'uv/libc'
local uv_buf_t = require 'uv/ctypes/uv_buf_t'
local uv_signal_t = require 'uv/ctypes/uv_signal_t'
local uv_process_t = require 'uv/ctypes/uv_process_t'
local uv_process_options_t = require 'uv/ctypes/uv_process_options_t'
local join = require 'uv/util/join'
local verify = require 'uv/util/verify'

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
  verify(libuv.uv_kill(pid, signum))
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
  verify(libuv.uv_getrusage(usage))
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

function process.title(value)
  local buf = uv_buf_t()
  verify(libuv.uv_get_process_title(buf.base, buf.len))
  local title = ffi.string(buf.base)
  buf:free()
  if value then
    verify(uv_set_process_title(value))
  end
  return title
end

function process.spawn(args)
  local options = uv_process_options_t()

  options.exit_cb = async.uv_exit_cb

  assert(#args >= 1, 'path to executable required')
  options.file = args[1]

  options.args = ffi.new('char*[?]', #args + 1)
  for i, arg in ipairs(args) do
    options.args[i - 1] = ffi.cast('char*', arg)
  end

  options.stdio_count = 3
  local stdio = ffi.new('uv_stdio_container_t[?]', 3)
  options.stdio = stdio

  if type(args.stdin) == 'number' then
    options.stdio[0].flags = libuv.UV_INHERIT_FD
    options.stdio[0].data.fd = args.stdin
  end

  if type(args.stdout) == 'number' then
    options.stdio[1].flags = libuv.UV_INHERIT_FD
    options.stdio[1].data.fd = args.stdout
  end

  if type(args.stderr) == 'number' then
    options.stdio[2].flags = libuv.UV_INHERIT_FD
    options.stdio[2].data.fd = args.stderr
  end

  if args.uid then
    options.uid = args.uid
    options.flags = bit.bor(options.flags, libuv.UV_PROCESS_SETUID)
  end

  if args.gid then
    options.gid = args.gid
    options.flags = bit.bor(options.flags, libuv.UV_PROCESS_SETGID)
  end

  local req = uv_process_t()
  local term_signal = req:spawn(options)
  options:free()
  return term_signal
end

return process
