local uv = require 'uv'
local fs = require 'uv.fs'

uv.run(function()
  local file = fs.open('README.md')
  repeat
    local chunk = file:read()
    io.write(chunk)
  until chunk == ''
  file:close()
end)
