require 'uv/cdef'
local ffi = require 'ffi'
local async = require 'async'
local ctype = require 'ctype'
local libuv = require 'uv/libuv'
local libuv2 = require 'uv/libuv2'
local octal = require 'uv/octal'

--------------------------------------------------------------------------------
-- uv_statbuf_t
--------------------------------------------------------------------------------

local uv_statbuf_t = ctype('uv_statbuf_t')

local S_IFMT		 = octal('0170000')  -- [XSI] type of file mask
local S_IFIFO		 = octal('0010000')  -- [XSI] named pipe (fifo)
local S_IFCHR		 = octal('0020000')  -- [XSI] character special
local S_IFDIR		 = octal('0040000')  -- [XSI] directory
local S_IFBLK		 = octal('0060000')  -- [XSI] block special
local S_IFREG		 = octal('0100000')  -- [XSI] regular
local S_IFLNK		 = octal('0120000')  -- [XSI] symbolic link
local S_IFSOCK	 = octal('0140000')  -- [XSI] socket

function uv_statbuf_t:uid()
  return self.st_uid
end

function uv_statbuf_t:gid()
  return self.st_gid
end

function uv_statbuf_t:size()
  return self.st_size
end

function uv_statbuf_t:mode()
  return bit.band(self.st_mode, bit.bnot(S_IFMT))
end

function uv_statbuf_t:is_dir()
  return bit.band(self.st_mode, S_IFDIR) > 0
end

function uv_statbuf_t:is_fifo()
  return bit.band(self.st_mode, S_IFIFO) > 0
end

do
  local ok, err = pcall(function() return ffi.new('uv_statbuf_t').st_atime end)
  if ok then
    function uv_statbuf_t:atime()         return self.st_atime end
    function uv_statbuf_t:atimensec()     return self.st_atimensec end
    function uv_statbuf_t:mtime()         return self.st_mtime end
    function uv_statbuf_t:mtimensec()     return self.st_mtimensec end
    function uv_statbuf_t:ctime()         return self.st_ctime end
    function uv_statbuf_t:ctimensec()     return self.st_ctimensec end
    function uv_statbuf_t:birthtime()     return self.st_birthtime end
    function uv_statbuf_t:birthtimensec() return self.st_birthtimensec end
  else
    assert(err:find('st_atime'), err)
    function uv_statbuf_t:atime()         return self.st_atimespec.tv_sec end
    function uv_statbuf_t:atimensec()     return self.st_atimespec.tv_nsec end
    function uv_statbuf_t:mtime()         return self.st_mtimespec.tv_sec end
    function uv_statbuf_t:mtimensec()     return self.st_mtimespec.tv_nsec end
    function uv_statbuf_t:ctime()         return self.st_ctimespec.tv_sec end
    function uv_statbuf_t:ctimensec()     return self.st_ctimespec.tv_nsec end
    function uv_statbuf_t:birthtime()     return self.st_birthtimespec.tv_sec end
    function uv_statbuf_t:birthtimensec() return self.st_birthtimespec.tv_nsec end
  end
end

-- dev_t    st_dev;     /* [XSI] ID of device containing file */ \
-- mode_t   st_mode;    /* [XSI] Mode of file (see below) */ \
-- nlink_t    st_nlink;   /* [XSI] Number of hard links */ \
-- __darwin_ino64_t st_ino;   /* [XSI] File serial number */ \
-- uid_t    st_uid;     /* [XSI] User ID of the file */ \
-- gid_t    st_gid;     /* [XSI] Group ID of the file */ \
-- dev_t    st_rdev;    /* [XSI] Device ID */ \

-- -- darwin
-- struct timespec st_atimespec;    /* time of last access */ \
-- struct timespec st_mtimespec;    /* time of last data modification */ \
-- struct timespec st_ctimespec;    /* time of last status change */ \
-- struct timespec st_birthtimespec;  /* time of file creation(birth) */
-- 
-- -- posix
-- time_t   st_atime;   /* [XSI] Time of last access */ \
-- long   st_atimensec;   /* nsec of last access */ \
-- time_t   st_mtime;   /* [XSI] Last data modification time */ \
-- long   st_mtimensec;   /* last data modification nsec */ \
-- time_t   st_ctime;   /* [XSI] Time of last status change */ \
-- long   st_ctimensec;   /* nsec of last status change */ \
-- time_t   st_birthtime;   /*  File creation time(birth)  */ \
-- long   st_birthtimensec; /* nsec of File creation time */

-- off_t    st_size;    /* [XSI] file size, in bytes */ \
-- blkcnt_t st_blocks;    /* [XSI] blocks allocated for file */ \
-- blksize_t  st_blksize;   /* [XSI] optimal blocksize for I/O */ \
-- __uint32_t st_flags;   /* user defined flags for file */ \
-- __uint32_t st_gen;     /* file generation number */ \
-- __int32_t  st_lspare;    /* RESERVED: DO NOT USE! */ \
-- __int64_t  st_qspare[2];   /* RESERVED: DO NOT USE! */ \

return uv_statbuf_t
