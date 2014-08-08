local uv = require 'uv'

do
  local dir = os.tmpname()
  os.remove(dir)
  uv.run(function()
    local fs = uv.fs()
    fs:mkdir(dir)
    fs:rmdir(dir)
  end)
end

print('All tests passing')
