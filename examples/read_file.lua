local uv = require 'uv'

uv.run(function()
  local fs = uv.fs()
  local file = fs:open('README.md')
  repeat
    local chunk = fs:read(file)
    io.write(chunk)
  until chunk == ''
  fs:close(file)
end)
