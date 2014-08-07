require 'strict'
local ffi = require 'ffi'
local uv = require 'uv'

local loop = uv.default_loop();

local server = loop:tcp()
server:bind('0.0.0.0', 7000)

server:listen(function(server, status)
  if tonumber(status) == -1 then
    print('error status')
    return
  end

  print('client connected')

  local client = server.loop:tcp()

  if server:accept(client) then
    client:read(function(stream, nread, buf_base, buf_len)
      if nread >= 0 then
        local buffer = ffi.string(buf_base, nread)
        print('read ' .. tonumber(nread) .. ' bytes: ', (string.format('%q', buffer):gsub('\\\n', '\\n')))
      else
        stream:close()
        print('connection closed')
      end
    end)
  else
    print('accept failed')
    client:close()
  end
end)

print('running event loop')
return loop:run()
