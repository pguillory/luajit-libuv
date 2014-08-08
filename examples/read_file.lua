local uv = require 'uv'
local this_file = debug.getinfo(1).source:sub(2)

uv.run(function()
  local file = uv.fs():open(this_file)
  repeat
    local chunk = file:read()
    io.write(chunk)
  until chunk == ''
  file:close()
end)
