luajit-libuv [![build status](https://travis-ci.org/pguillory/luajit-libuv.svg)](https://travis-ci.org/pguillory/luajit-libuv)
============

This project provides a [LuaJIT FFI] binding to [libuv], the async I/O library
powering [Node.js]. It uses Lua coroutines to provide non-blocking I/O with
synchronous syntax.

For example, you can build a web server that performs I/O (like reading a file
or talking to a database) while generating each response, and it will process
multiple requests simultaneously.

```lua
local http = require 'uv.http'
local fs = require 'uv.fs'

http.listen('127.0.0.1', 8080, function(request)
  return { status = 200, body = fs.readfile('README.md') }
end)
```

Or you can perform multiple HTTP requests simultaneously.

```lua
local http = require 'uv.http'
local parallel = require 'uv.parallel'

local requests = {
  { url = 'http://www.google.com/' },
  { url = 'http://www.bing.com/' },
  { url = 'http://www.amazon.com/' },
}

local responses = parallel.map(requests, http.request)
```

Status
------

Not production ready. Under active development. The API is unstable.

Requirements
------------

- [LuaJIT]. Regular Lua won't run it. That said, you probably want LuaJIT
  anyway.

- Standard build tools.

- [libuv] and [http-parser] are bundled and do not need to be installed
  separately.

Installation
------------

```bash
git clone https://github.com/pguillory/luajit-libuv.git
cd luajit-libuv
make
make install
```

API Reference
-------------

Functions are divided into submodules. Each submodule can either be required directly or accessed indirectly through the `uv` module:

```lua
local fs = require 'uv.fs'

local uv = require 'uv'
local fs = uv.fs
```

* [uv.fs](doc/fs.md) - File system
* [uv.http](doc/http.md) - HTTP client and server
* [uv.loop](doc/loop.md) - Event loop control
* [uv.parallel](doc/parallel.md) - Parallel processing
* [uv.process](doc/process.md) - Process management
* [uv.system](doc/system.md) - System utility functions
* [uv.timer](doc/timer.md) - Timers
* [uv.url](doc/url.md) - URL parsing and encoding

Contributing
------------

Your contributions are welcome! Please verify that `make test` succeeds and
submit your changes as a pull request.

See Also
--------

Other people have done things like this.

- [luvit](https://github.com/luvit/luvit)
- [LuaNode](https://github.com/ignacio/LuaNode)
- [lev](https://github.com/connectFree/lev)
- [luv](https://github.com/luvit/luv)
- [luauv](https://github.com/grrrwaaa/luauv)
- [uv](https://github.com/steveyen/uv)
- [lua-uv](https://github.com/bnoordhuis/lua-uv/)
- [Ray](https://github.com/richardhundt/luv/tree/ray)

[Luajit FFI]: http://luajit.org/ext_ffi.html
[libuv]: https://github.com/joyent/libuv
[Node.js]: http://nodejs.org/
[luv]: https://github.com/creationix/luv
[http-parser]: https://github.com/joyent/http-parser
[LuaJIT]: http://luajit.org/
[FIFO]: http://en.wikipedia.org/wiki/Named_pipe
