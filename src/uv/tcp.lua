require 'uv/ctypes/init'
local class = require 'uv/util/class'
local ffi = require 'ffi'
local libuv = require 'uv/libuv'
local libuv2 = require 'uv/libuv2'
local uv_tcp_t = require 'uv/ctypes/uv_tcp_t'
local join = require 'uv/util/join'

local tcp = {}

function tcp.listen(host, port, callback)
  local server = uv_tcp_t()
  server:bind(host, port)
  join(coroutine.create(function()
    server:listen(function()
      join(coroutine.create(function()
        local client = uv_tcp_t()
        local ok, err = pcall(function()
          if server:accept(client) then
            callback(client)
          end
        end)
        client:close()
        if not ok then
          io.stderr:write(err .. '\n')
          io.flush()
        end
      end))
    end)
  end))
  if not coroutine.running() then
    libuv.uv_default_loop():run()
  end
  return server
end

function tcp.connect(host, port, callback)
  local req = uv_tcp_t()
  local client = req:connect(host, tonumber(port))
  return client
end

return tcp
