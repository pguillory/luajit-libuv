local ffi = require 'ffi'
local join = require 'uv/join'

local async = {}

function async.func(cb_type, func)
  local threads = {}

  local function yield(self)
    local id = tostring(self):sub(-8)
    threads[id] = assert(coroutine.running(), 'not in a coroutine')
    return coroutine.yield()
  end

  local resume = ffi.cast(cb_type, function(self, ...)
    local id = tostring(self):sub(-8)
    local thread = assert(threads[id], 'thread not found')
    threads[id] = nil
    return join(thread, ...)
  end)

  return function(...)
    return func(yield, resume, ...)
  end
end

function async.server(cb_type, func)
  local callbacks = {}

  local function yield(self, callback)
    table.insert(callbacks, callback)
    self.data = ffi.cast('void*', #callbacks)
  end

  local resume = ffi.cast(cb_type, function(self, ...)
    local id = tonumber(ffi.cast('int', self.data))
    local callback = assert(callbacks[id], 'callback not found')
    local thread = coroutine.create(callback)
    return join(thread, self, ...)
  end)

  return function(...)
    return func(yield, resume, ...)
  end
end

return async
