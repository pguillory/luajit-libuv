luajit-libuv
============

Status: *work in progress, just got started*

This project provides a [Luajit FFI] binding for the [libuv] library, which
powers the async I/O behind [Node.js] and others. In contrast to [luv], it
relies on Lua coroutines to generate provide asynchronous I/O behavior with
synchronous syntax.

The API is a thin wrapper around `libuv`. It frequently returns the `libuv` structs themselves with additional methods attached via `ffi.metatype`.

Usage
-----

```lua
local uv = require 'uv'
local fs = require 'uv.fs'
local http = require 'uv.http'

uv.run(function()
  -- Let's handle web requests...
  http.listen('127.0.0.1', 80, function(request)
    return 200, {}, 'Hello world!'
  end)

  -- ...while simultaneously streaming a file to stdout. Why not.
  local file = fs.open('README.md')
  repeat
    local chunk = file:read()
    io.write(chunk)
  until chunk == ''
  file:close()
end)
```

Installation
------------

```bash
git clone git@github.com:pguillory/luajit-libuv.git
cd luajit-libuv
make
make test

# To run an example:
export LUA_PATH="src/?.lua;;"
luajit examples/read_file.lua 
```

[Luajit FFI]: http://luajit.org/ext_ffi.html
[libuv]: https://github.com/joyent/libuv
[Node.js]: http://nodejs.org/
[luv]: https://github.com/creationix/luv
