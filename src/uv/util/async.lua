local ffi = require 'ffi'
local join = require 'uv/util/join'
local libuv = require 'uv/libuv'

local async, threads, id = {}, {}, 0
setmetatable(async, async)

local red_on_black = '\27[31;40m'
local green_on_black = '\27[32;40m'
local yellow_on_black = '\27[33;40m'
local white_on_black = '\27[37;40m'

local function log(color, method, id, req, info)
  local source = info.short_src .. ':' .. info.currentline
  print(string.format('%s%-8s %-5i %-42s %-10s %s%s', color, method, id, req, info.name, source, white_on_black))
  io.flush()
end

function async.yield(req)
  local thread = coroutine.running()

  if not thread then
    local retval
    local thread = coroutine.create(function()
      retval = { async.yield(req) }
    end)
    local ok = coroutine.resume(thread)
    libuv.uv_default_loop():run()
    return unpack(retval)
  end

  while threads[id] do
    id = bit.band(id + 1, 0xFFFFFFFFFFFF) -- lower 48 bits
  end
  -- log(yellow_on_black, 'yield', id, req, debug.getinfo(2))
  req.data = ffi.cast('void*', id)
  threads[id] = thread
  return coroutine.yield()
end

function async.resume(req, ...)
  local id = tonumber(ffi.cast('int', req.data))
  local thread = threads[id]
  -- log(green_on_black, 'resume', id, req, debug.getinfo(thread, 1))
  threads[id] = nil
  return join(thread, ...)
end

function async:__index(ctype)
  self[ctype] = ffi.cast(ctype, self.resume)
  return self[ctype]
end

return async
