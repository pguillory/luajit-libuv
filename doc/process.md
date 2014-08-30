API Reference - uv.process
==========================

The `process` module provides functions for managing processes.

### process.spawn(args)

Spawn a child process. `args` should be a table containing the executable path
at index 1, arguments at indexes 2+, and any of the following options:

- `env`: A table of environment variables as key/value pairs. If `env` is
  omitted, the child process will inherit the parent's environment.

- `cwd`: Current working directory of the child process.

- `stdin`: File descriptor to inherit as stdin. 0 causes it to inherit the
  parent's stdin.

- `stdout`: File descriptor to inherit as stdout. 1 causes it to inherit the
  parent's stdout.

- `stderr`: File descriptor to inherit as stderr. 2 causes it to inherit the
  parent's stderr.

- `uid`: User ID under which to run.

- `gid`: Group ID under which to run.

Returns the signal that terminated the child process, or 0 on successful exit.

```lua
local signal = process.spawn { '/bin/echo', 'Hello', 'world' }

local file = fs.open('out.txt', 'w')
process.spawn { '/bin/ls', cwd = fs.cwd(), stdout = file.descriptor }
```

### process.pid()

Returns the current process's PID.

### process.path()

Returns the path to the executable for the current process.

### process.kill(pid, signal)

Send a signal to a process. `signal` defaults to "SIGKILL" and can have any of
the following values:

- "SIGKILL": The process should exit.
- "SIGINT": The user pressed Control+C.
- "SIGHUP": The user closed the console window.
- "SIGWINCH": The user resized the console window.

### process.on(signal, callback)

Call `callback` when a given signal is received. `signal` can only be "SIGINT", "SIGHUP", or "SIGWINCH".

```lua
process.on('SIGINT', function()
  print('Shutting down...')
  os.exit()
end)
```

### process.usage()

Returns a table describing the current process's resource usage with the
following keys:

- `utime`: User CPU time used, in microseconds.
- `stime`: System CPU time used, in microseconds.
- `maxrss`: Maximum resident set size.
- `ixrss`: Integral shared memory size.
- `idrss`: Integral unshared data size.
- `isrss`: Integral unshared stack size.
- `minflt`: Page reclaims (soft page faults).
- `majflt`: Page faults (hard page faults).
- `nswap`: Swaps.
- `inblock`: Block input operations.
- `oublock`: Block output operations.
- `msgsnd`: IPC messages sent.
- `msgrcv`: IPC messages received.
- `nsignals`: Signals received.
- `nvcsw`: Voluntary context switches.
- `nivcsw`: Involuntary context switches.

### process.title(value)

Change the current process's title to `value`, if present. Returns the
existing title. I think this only works on Windows.
