local ffi = require 'ffi'

local async = {}

function async.func(cb_type, func)
  local threads = {}

  local function yield(req)
    local id = tostring(req):sub(-8)
    -- print('callback ', req, id)
    threads[id] = assert(coroutine.running(), 'not in a coroutine')
    return coroutine.yield()
  end

  local callback = ffi.cast(cb_type, function(req, ...)
    local id = tostring(req):sub(-8)
    -- print('callback ', req, id)
    local thread = threads[id]
    if not thread then
      error('thread not found: ' .. id .. ' -- ' .. tostring(req))
    end
    threads[id] = nil
    local ok, err = coroutine.resume(thread, ...)
    if not ok then
      error(debug.traceback(thread, err), 0)
    end
  end)

  return function(...)
    return func(yield, callback, ...)
  end
end

function async.server(cb_type, func)
  local callbacks = {}

  local function yield(self, callback)
    table.insert(callbacks, callback)
    self.data = ffi.cast('void*', #callbacks)
  end

  local callback = ffi.cast(cb_type, function(self, ...)
    local id = tonumber(ffi.cast('int', self.data))
    local callback = callbacks[id]
    assert(callback, 'callback not found')
    local thread = coroutine.create(callback)
    local ok, err = coroutine.resume(thread, self, ...)
    if not ok then
      error(debug.traceback(thread, err), 0)
    end
  end)

  return function(...)
    return func(yield, callback, ...)
  end
end

return async
