local loop = require 'uv.loop'
local http = require 'uv.http'
local system = require 'uv.system'

loop.run(function()
  local server = http.listen('127.0.0.1', 7000, function(request)
    return 200, {}, 'ok'
  end)
  local count = 1000
  local time1 = system.hrtime()
  for i = 1, count do
    http.request { url = 'http://127.0.0.1:7000/' }
  end
  local time2 = system.hrtime()
  print(count .. ' requests took ' .. (time2 - time1) .. ' seconds')
  server:close()
end)
