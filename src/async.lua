local ffi = require 'ffi'

local async = {}

function async.func(func)
  local threads = {}

  local function yield(req)
    local id = tostring(req):sub(-8)
    -- print('callback ', req, id)
    threads[id] = assert(coroutine.running(), 'not in a coroutine')
    return coroutine.yield()
  end

  local function callback(req, ...)
    local id = tostring(req):sub(-8)
    -- print('callback ', req, id)
    local thread = threads[id]
    if not thread then
      error('thread not found: ' .. id .. ' -- ' .. tostring(req))
    end
    threads[id] = nil
    return assert(coroutine.resume(thread, ...))
  end

  return function(...)
    return func(yield, callback, ...)
  end
end

function async.server(func)
  local callbacks = {}

  local function yield(self, callback)
    table.insert(callbacks, callback)
    self.data = ffi.cast('void*', #callbacks)
  end

  local function callback(self, ...)
    local id = tonumber(ffi.cast('int', self.data))
    local callback = callbacks[id]
    assert(callback, 'callback not found')
    local thread = coroutine.create(callback)
    return assert(coroutine.resume(thread, self, ...))
  end

  return function(...)
    return func(yield, callback, ...)
  end
end

return async
