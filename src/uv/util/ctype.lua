local ffi = require 'ffi'

local function ctype(name, constructor, destructor)
  local metatype = {}
  local metatable = {}
  metatype.__index = metatype
  local ctype = ffi.metatype(name, metatype)
  local sizeof = ffi.sizeof(ctype)
  assert(sizeof > 0)
  if constructor then
    function metatable:__call(...)
      return constructor(...)
    end
  else
    function metatable:__call(...)
      return ctype(...)
    end
  end
  return setmetatable(metatype, metatable)
end

return ctype
