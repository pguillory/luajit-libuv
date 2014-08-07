local ffi = require 'ffi'

function ctype(name, destructor)
  local ctype, mt = {}, {}
  ctype.__index = ctype
  ffi.metatype(name, ctype)
  function mt:__call(cdata)
    return ffi.gc(cdata, destructor or ffi.C.free)
  end
  return setmetatable(ctype, mt)
end

return ctype
