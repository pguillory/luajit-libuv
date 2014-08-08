require 'strict'
local ffi = require 'ffi'
local uv = require 'uv'

uv.run(function()
  print('in coroutine')
  local file = uv.open('Makefile')
  print('file: ', file)
  print('read: ---\n', file:read(), '\n---')
end)
