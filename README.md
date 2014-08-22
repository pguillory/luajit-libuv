luajit-libuv ![build status](https://travis-ci.org/pguillory/luajit-libuv.svg)
============

Status: *in development*

This project provides a [Luajit FFI] binding for the [libuv] library, which
powers the async I/O behind [Node.js] and others. In contrast to [luv], it
uses Lua coroutines to enable asynchronous I/O behavior with synchronous
syntax.

Requirements
------------

Just standard C build tools. [libuv] and [http-parser] are bundled. A bundled
version of [luajit] is used to run the tests.

Installation
------------

```bash
git clone https://github.com/pguillory/luajit-libuv.git
cd luajit-libuv
make
make install
```

Usage
-----

A simple web server.

```lua
local timer = require 'uv.timer'
local http = require 'uv.http'

http.listen('127.0.0.1', 80, function(request)
  timer.sleep(5000)
  return 200, {}, 'Hello world!'
end)
```

API Reference
-------------

**timer.set(timeout, callback)**

Schedule a function to be called once in the future. Returns immediately.

```lua
timer.set(5000, function()
  print('Ding!')
end)
print('Waiting 5 seconds...')
uv.run()
print('The timer dinged.')
```

**timer.every(timeout, callback)**

Schedule a function to be called every `timeout` milliseconds. Returns
immediately.

```lua
timer.every(1000, function(t)
  print('Tick...')
  if we_are_done then
    t:stop()
  end
end)
uv.run()
```

**timer.sleep(timeout, callback)**

Yield the current coroutine for `timeout` milliseconds.

```lua
print('Going to sleep...')
timer.sleep(5000)
print('Woke up')
```

**fs.open(path, flags, mode)**

Open a file. `flags` can have the following values:

- `r`: reading
- `w`: writing, truncate it if it exists, otherwise create it
- `a`: appending if it exists, otherwise create it
- `r+`: reading and writing
- `w+`: reading and writing, truncate it if it exists, otherwise create it
- `a+`: reading and appending if it exists, otherwise create it

`mode` sets access permissions on the file if it is created. It can be a
number or an octal string. '700' means a file is only accessible by you. '777'
means it is accessible by anyone.

Returns a file object.

```lua
local file = fs.open('/path/to/file.txt', 'w', '755')
file:write('hello world')
file:close()
```

**fs.unlink(path)**

Delete a file.

**fs.mkdir(path, mode)**

Create a directory. See `fs.open` for documentation on `mode`.

**fs.rmdir(path)**

Delete a directory. It must be empty.

**fs.chmod(path, mode)**

Change the permissions of a file/directory. See `fs.open` for documentation on
`mode`.

**fs.chown(path, uid, gid)**

Change the owner of a file/directory. `uid` and `gid` should be numbers.

**fs.stat(path)**

Retrieve information about a file/directory. Returns a table with the following keys:

- `uid`:            User who owns the file.
- `gid`:            Group that owns the file.
- `size`:           File size in bytes.
- `mode`:           Access permissions. See `fs.open`.
- `is_dir`:         `true` if it is a directory.
- `is_fifo`:        `true` if it is a [FIFO].
- `atime`:          Time the file was last accessed (second precision).
- `atimensec`:      Time the file was last accessed (nanosecond precision).
- `mtime`:          Time the file was last accessed (second precision).
- `mtimensec`:      Time the file was last accessed (nanosecond precision).
- `ctime`:          Time the file was last changed (second precision).
- `ctimensec`:      Time the file was last changed (nanosecond precision).
- `birthtime`:      Time the file was created (second precision).
- `birthtimensec`:  Time the file was created (nanosecond precision).

**fs.lstat(path)**

Same as `fs.stat`, but doesn't follow symlinks.

**fs.rename(path, new_path)**

Rename a file.

**fs.link(path, new_path)**

Create a hard link.

**fs.symlink(path, new_path)**

Create a symlink.

**fs.readlink(path)**

Read the value of a symlink.

**fs.readfile(path)**

Get the full contents of a file as a string.

**fs.writefile(path, body)**

Write a string to a file. Truncates the file if it already exists.

**fs.tmpname()**

Get a temporary filename.

**fs.cwd()**

Get the current working directory.

**fs.chdir(dir)**

Change the current working directory.

**fs.readdir(path)**

Get a list of files/subdirectories in a directory.

**fs.readdir_r(path)**

Get a list of all files under a directory and its descendent subdirectories.
Returns a flat list of filenames.

```lua
fs.with_tempdir(function(dir)
  fs.chdir(dir)
  fs.writefile('a', '')
  fs.writefile('b', '')
  fs.mkdir('c')
  fs.writefile('c/d', '')
  local filenames = fs.readdir_r('.')
  # filenames == { 'a', 'b', 'c/d' }
end)
```

**fs.rm_rf(path)**

Delete a file or directory. If it is a directory, its contents are deleted as well. *Be careful with this one!*

**fs.dirname(filename)**

**fs.basename(filename)**

**fs.extname(filename)**

Extract the directory, basename, and extension from a filename, respectively.

```lua
assert(fs.dirname ('/path/to/file.txt') == '/path/to/')
assert(fs.basename('/path/to/file.txt') == 'file')
assert(fs.extname ('/path/to/file.txt') == '.txt')
```

**fs.with_tempdir(callback)**

Create a directory, pass it to a callback, and delete the directory when the
callback returns.

```lua
fs.with_tempdir(function(dir)
  # dir will be something like '/tmp/lua_bVjBeR'
end)
```

**uv.run()**

Run the libuv event loop. This is only necessary if an I/O request was created
in a coroutine without the event loop already running. Requests made outside a
coroutine are performed synchronously. It returns when the last I/O request is
finished.

```lua
print(uv.fs.readfile('README.md'))
```

In this example, we're not in a coroutine, so `fs.readfile` ran the event loop
implicitly. There is no need to call `uv.run()`.

```lua
coroutine.resume(coroutine.create(function()
  print(uv.fs.readfile('README.md'))
end))
uv.run()
```

Here, we manually created a coroutine that called `fs.readfile`, which yielded
while awaiting the result. The event loop is not running, so unless we called
`uv.run()`, the program would exit without performing the I/O request and the
coroutine would never resume.

[Luajit FFI]: http://luajit.org/ext_ffi.html
[libuv]: https://github.com/joyent/libuv
[Node.js]: http://nodejs.org/
[luv]: https://github.com/creationix/luv
[http-parser]: https://github.com/joyent/http-parser
[luajit]: http://luajit.org/
[FIFO]: http://en.wikipedia.org/wiki/Named_pipe
