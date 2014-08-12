local function class(constructor, parent)
  local class, mt = {}, {}
  class.__index = class
  if constructor then
    function mt:__call(...)
      return setmetatable(constructor(...), self)
    end
  else
    function mt:__call()
      return setmetatable({}, self)
    end
  end
  if parent then
    mt.__index = parent
  end
  return setmetatable(class, mt)
end

return class
