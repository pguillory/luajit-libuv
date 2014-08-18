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
local uv = require 'uv'
local timer = require 'uv.timer'
local http = require 'uv.http'

uv.run(function()
  http.listen('127.0.0.1', 80, function(request)
    timer.sleep(5000)
    return 200, {}, 'Hello world!'
  end)
end)
```

API Reference
-------------

**uv.run(callback)**

Your entire application should be wrapped in a `uv.run` call. The callback function gets called with the event loop running. It returns when the last I/O request is finished.

```lua
uv.run(function()
  // program goes here
end)
```

**timer.set(timeout, callback)**

Schedule a function to be called once in the future. Returns immediately.

```lua
uv.run(function()
  timer.set(5000, function()
    print('Ding!')
  end)
  print('Waiting 5 seconds...')
end)
print('The timer dinged.')
```

**timer.every(timeout, callback)**

Schedule a function to be called every `timeout` milliseconds. Returns immediately.

```lua
uv.run(function()
  timer.set(5000, function(t)
    print('Tick...')
    if we_are_done then
      t:stop()
    end
  end)
end)
```

**timer.sleep(timeout, callback)**

Yield the current coroutine for `timeout` milliseconds.

```lua
uv.run(function()
  print('Going to sleep...')
  timer.sleep(5000)
  print('Woke up')
end)
```

[Luajit FFI]: http://luajit.org/ext_ffi.html
[libuv]: https://github.com/joyent/libuv
[Node.js]: http://nodejs.org/
[luv]: https://github.com/creationix/luv
[http-parser]: https://github.com/joyent/http-parser
[luajit]: http://luajit.org/
