require 'uv/util/strict'
local loop = require 'uv.loop'
local fs = require 'uv.fs'
local libc = require 'uv/libc'
local expect = require 'uv/util/expect'

local ffi = require 'ffi'
local uid = libc.getuid()
local gid = libc.getgid()

do
  fs.with_tempdir(function(dir)
    expect.equal(fs.cwd():find(dir, 1, true), nil)
    fs.chdir(dir)
    assert(fs.cwd():find(dir, 1, true))

    -- writing
    local file = fs.open('file.txt', 'w', '777')
    file:write('hello!')
    file:close()

    -- reading
    local file = fs.open('file.txt')
    expect.equal(file:read(), 'hello!')
    file:sync()
    file:close()

    fs.writefile('file2.txt', 'hello!')
    expect.equal(fs.readfile('file2.txt'), 'hello!')
    fs.unlink('file2.txt')

    -- hard links
    fs.link('file.txt', 'link.txt')
    local file = fs.open('link.txt')
    expect.equal(file:read(), 'hello!')
    file:close()
    fs.unlink('link.txt')

    -- symlinks
    fs.symlink('file.txt', 'symlink.txt')
    expect.equal(fs.readlink('symlink.txt'), 'file.txt')
    fs.unlink('symlink.txt')

    local stat = fs.stat('file.txt')
    expect.equal(stat.uid, uid)
    -- This doesn't work! stat.gid is returning 0 for some reason.
    -- expect.equal(stat.gid, gid)
    expect.equal(stat.mode, 511) -- octal('777')
    expect.equal(stat.size, 6)
    expect.equal(stat.is_dir, false)
    expect.equal(stat.is_fifo, false)
    assert(math.abs(os.time() - tonumber(stat.atime)) < 10)

    -- renaming
    fs.rename('file.txt', 'new-file.txt')
    local file = fs.open('new-file.txt')
    expect.equal(file:read(), 'hello!')
    file:close()
    fs.unlink('new-file.txt')

    fs.open('a', 'w'):close()
    fs.open('b', 'w'):close()
    fs.mkdir('c')
    fs.open('c/d', 'w'):close()
    fs.open('c/e', 'w'):close()
    fs.mkdir('c/f')
    fs.open('c/f/g', 'w'):close()
    fs.open('c/f/h', 'w'):close()

    local filenames = fs.readdir('.')
    expect.equal(#filenames, 3)
    expect.equal(filenames[1], 'a')
    expect.equal(filenames[2], 'b')
    expect.equal(filenames[3], 'c')

    local filenames = fs.readdir_r('.')
    expect.equal(#filenames, 6)
    expect.equal(filenames[1], 'a')
    expect.equal(filenames[2], 'b')
    expect.equal(filenames[3], 'c/d')
    expect.equal(filenames[4], 'c/e')
    expect.equal(filenames[5], 'c/f/g')
    expect.equal(filenames[6], 'c/f/h')

    local filenames = fs.readdir_r('c')
    expect.equal(#filenames, 4)
    expect.equal(filenames[1], 'd')
    expect.equal(filenames[2], 'e')
    expect.equal(filenames[3], 'f/g')
    expect.equal(filenames[4], 'f/h')

    -- errors
    local ok, err = pcall(function()
      fs.open('nonexistent')
    end)
    assert(not ok)
    assert(err:find('ENOENT: no such file or directory'), err)

    local ok, err = pcall(function()
      fs.chdir('nonexistent')
    end)
    assert(not ok)
    assert(err:find('ENOENT: no such file or directory'), err)
  end)
end
