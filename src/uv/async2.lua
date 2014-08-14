local ffi = require 'ffi'
local join = require 'uv/join'

local async2, threads, id = {}, {}, 0
setmetatable(async2, async2)

function async2.yield(req)
  while threads[id] do
    id = bit.band(id + 1, 0xFFFFFFFFFFFF) -- lower 48 bits
  end
  req.data = ffi.cast('void*', id)
  threads[id] = coroutine.running()
  return coroutine.yield()
end

function async2.resume(req, ...)
  local id = tonumber(ffi.cast('int', req.data))
  local thread = threads[id]
  threads[id] = nil
  return join(thread, ...)
end

function async2:__index(ctype)
  self[ctype] = ffi.cast(ctype, self.resume)
  return self[ctype]
end

return async2
