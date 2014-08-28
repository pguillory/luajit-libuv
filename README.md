luajit-libuv [![build status](https://travis-ci.org/pguillory/luajit-libuv.svg)](https://travis-ci.org/pguillory/luajit-libuv)
============

Status: *in development*

This project provides a [LuaJIT FFI] binding to [libuv], the async I/O library
powering [Node.js]. It uses Lua coroutines to provide non-blocking I/O with
synchronous syntax.

For example, you can build a web server that performs I/O (like reading a file
or talking to a database) while generating each response, and it will process
multiple requests simultaneously.

```lua
local http = require 'uv.http'
local fs = require 'uv.fs'

http.listen('127.0.0.1', 80, function(request)
  return 200, {}, fs.readfile('hello.txt')
end)
```

Or you can perform multiple HTTP requests simultaneously.

```lua
local http = require 'uv.http'
local parallel = require 'uv.parallel'

local requests = {
  { url = 'http://example.com/page1' },
  { url = 'http://example.com/page2' },
}
local responses = parallel.map(requests, http.request)
```

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

* [fs](doc/fs.md) - File system
* [http](doc/http.md) - HTTP client and server
* [parallel](doc/parallel.md) - Parallel processing
* [timer](doc/timer.md) - Timers
* [url](doc/url.md) - URL parsing and encoding
* [uv](doc/uv.md) - Utility functions

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

[Luajit FFI]: http://luajit.org/ext_ffi.html
[libuv]: https://github.com/joyent/libuv
[Node.js]: http://nodejs.org/
[luv]: https://github.com/creationix/luv
[http-parser]: https://github.com/joyent/http-parser
[LuaJIT]: http://luajit.org/
[FIFO]: http://en.wikipedia.org/wiki/Named_pipe
