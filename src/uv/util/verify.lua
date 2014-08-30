local errno = require 'uv/util/errno'

local function verify(status)
  if tonumber(status) < 0 then
    error(errno[status], 2)
  end
  return tonumber(status)
end

return verify
