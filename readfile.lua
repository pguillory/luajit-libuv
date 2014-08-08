require 'strict'
local ffi = require 'ffi'
local uv = require 'uv'

uv.run(function()
  local file = uv.fs():open('Makefile')
  print('file: ', file)
  print('read: -->' .. file:read() .. '<--')
  print('read: -->' .. file:read() .. '<--')
  print('read: -->' .. file:read() .. '<--')
end)
