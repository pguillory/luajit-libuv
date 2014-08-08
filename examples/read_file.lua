local uv = require 'uv'
local this_file = debug.getinfo(1).source:sub(2)

uv.run(function()
  local fs = uv.fs()
  local file = fs:open(this_file)
  repeat
    local chunk = fs:read(file)
    io.write(chunk)
  until chunk == ''
  fs:close(file)
end)
