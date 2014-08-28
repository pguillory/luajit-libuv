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

A simple web server:

```lua
local http = require 'uv.http'

http.listen('127.0.0.1', 80, function(request)
  return 200, {}, 'Hello world!'
end)
```

API Reference
-------------

* [fs](doc/fs.md)
* [http](doc/http.md)
* [parallel](doc/parallel.md)
* [timer](doc/timer.md)
* [url](doc/url.md)
* [uv](doc/uv.md)

See Also
--------

Lots of people have done this before.

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
[luajit]: http://luajit.org/
[FIFO]: http://en.wikipedia.org/wiki/Named_pipe
