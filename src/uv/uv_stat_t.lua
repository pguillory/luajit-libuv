require 'uv/cdef'
local ffi = require 'ffi'
local async = require 'async'
local ctype = require 'ctype'
local libuv = require 'uv/libuv'

local function octal(s)
  local i = 0
  for c in s:gmatch('.') do
    i = i * 8 + tonumber(c)
  end
  return i
end

do
  assert(octal('0') == 0)
  assert(octal('1') == 1)
  assert(octal('10') == 8)
  assert(octal('11') == 9)
  assert(octal('100') == 64)
  assert(octal('101') == 65)
end

--------------------------------------------------------------------------------
-- uv_stat_t
--------------------------------------------------------------------------------

local uv_stat_t = ctype('uv_stat_t')

local S_IFMT		 = octal('0170000')  -- [XSI] type of file mask
local S_IFIFO		 = octal('0010000')  -- [XSI] named pipe (fifo)
local S_IFCHR		 = octal('0020000')  -- [XSI] character special
local S_IFDIR		 = octal('0040000')  -- [XSI] directory
local S_IFBLK		 = octal('0060000')  -- [XSI] block special
local S_IFREG		 = octal('0100000')  -- [XSI] regular
local S_IFLNK		 = octal('0120000')  -- [XSI] symbolic link
local S_IFSOCK	 = octal('0140000')  -- [XSI] socket

function uv_stat_t:uid()
  return self.st_uid
end

function uv_stat_t:gid()
  return self.st_gid
end

function uv_stat_t:size()
  return self.st_size
end

function uv_stat_t:mode()
  return bit.band(tonumber(self.st_mode), bit.bnot(S_IFMT))
end

function uv_stat_t:is_dir()
  return bit.band(tonumber(self.st_mode), S_IFDIR) > 0
end

function uv_stat_t:is_fifo()
  return bit.band(tonumber(self.st_mode), S_IFIFO) > 0
end

function uv_stat_t:atime()         return self.st_atim.tv_sec end
function uv_stat_t:atimensec()     return self.st_atim.tv_nsec end
function uv_stat_t:mtime()         return self.st_mtim.tv_sec end
function uv_stat_t:mtimensec()     return self.st_mtim.tv_nsec end
function uv_stat_t:ctime()         return self.st_ctim.tv_sec end
function uv_stat_t:ctimensec()     return self.st_ctim.tv_nsec end
function uv_stat_t:birthtime()     return self.st_birthtim.tv_sec end
function uv_stat_t:birthtimensec() return self.st_birthtim.tv_nsec end

return uv_stat_t
