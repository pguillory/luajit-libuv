require 'uv/util/strict'
local expect = require 'uv/util/expect'
local url = require 'uv.url'

do
  local function test(input, schema, userinfo, host, port, path, query, fragment)
    local parts = url.split(input)
    expect.equal(parts.schema, schema)
    expect.equal(parts.userinfo, userinfo)
    expect.equal(parts.host, host)
    expect.equal(parts.port, port)
    expect.equal(parts.path, path)
    expect.equal(parts.query, query)
    expect.equal(parts.fragment, fragment)
    expect.equal(url.join(parts), input)
  end

  test('http://user:pass@host:1234/path?a=1#section', 'http', 'user:pass', 'host', '1234', '/path', 'a=1', 'section')
  test(     '//user:pass@host:1234/path?a=1#section', nil,    'user:pass', 'host', '1234', '/path', 'a=1', 'section')
  test('http://'   ..   'host:1234/path?a=1#section', 'http', nil,         'host', '1234', '/path', 'a=1', 'section')
  test('http://user:pass@host'.. '/path?a=1#section', 'http', 'user:pass', 'host', nil,    '/path', 'a=1', 'section')
  test(                          '/path?a=1#section', nil,    nil,         nil,    nil,    '/path', 'a=1', 'section')
  test(                           'path?a=1#section', nil,    nil,         nil,    nil,    'path',  'a=1', 'section')
  test('http://user:pass@host:1234'.. '?a=1#section', 'http', 'user:pass', 'host', '1234', nil,     'a=1', 'section')
  test('http://user:pass@host:1234/path'..'#section', 'http', 'user:pass', 'host', '1234', '/path', nil,   'section')
  test('http://user:pass@host:1234/path?a=1',         'http', 'user:pass', 'host', '1234', '/path', 'a=1', nil)
  test('http://user:pass@host:1234',                  'http', 'user:pass', 'host', '1234', nil,     nil,   nil)
end

do
  local function test(input, expected)
    local actual = url.encode(input)
    expect.equal(actual, expected)
  end
  
  test('asdf', 'asdf')
  test(' ', '%20')
  test(1, '1')
  test(nil, '')
  test(false, 'false')
  test({}, '')
  test({ a = 1 }, 'a=1')
  test({ ['a b'] = 'c d' }, 'a%20b=c%20d')
end

do
  local function test(base, relative, expected)
    local actual = url.relative(base, relative)
    expect.equal(actual, expected)
  end

  test('/a/b/c',      '/d/e/f', '/d/e/f')
  test('/a/b/c',      'd/e/f',  '/a/b/d/e/f')
  test('/a/b/',       'd/e/f',  '/a/b/d/e/f')
  test('/a/b/c',      '',       '/a/b/c')
  test('/a/b/c?x=1',  '',       '/a/b/c?x=1')
  test('/a/b/c',      '?y=2',   '/a/b/c?y=2')
  test('/a/b/c?x=1',  '?y=2',   '/a/b/c?y=2')
end
