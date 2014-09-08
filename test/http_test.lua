require 'uv/util/strict'
local loop = require 'uv.loop'
local http = require 'uv.http'
local join = require 'uv/util/join'
local expect = require 'uv/util/expect'

--------------------------------------------------------------------------------
-- basic server
--------------------------------------------------------------------------------

loop.run(function()
  local server = http.listen('127.0.0.1', 7000, function(request)
    expect.equal(request.ip, '127.0.0.1')
    expect.equal(request.method, 'GET')
    expect.equal(request.path, '/path/to/route')
    expect.equal(request.query, 'a=1&b=2')
    expect.equal(request.headers['User-Agent'], 'test')

    return { status = 200, headers = { Expires = '-1' }, body = 'hello world' }
  end)

  local response = http.request {
    url = 'http://127.0.0.1:7000/path/to/route?a=1&b=2',
    headers = { ['User-Agent'] = 'test' },
  }

  expect.equal(response.status, 200)
  expect.equal(response.headers['Expires'], '-1')
  expect.equal(response.headers['Content-Length'], '11')
  expect.equal(response.body, 'hello world')

  local response = http.request{
    host = '127.0.0.1', port = 7000, path = '/path/to/route', query = 'a=1&b=2',
    headers = { ['User-Agent'] = 'test' },
  }

  expect.equal(response.status, 200)
  expect.equal(response.headers['Expires'], '-1')
  expect.equal(response.headers['Content-Length'], '11')
  expect.equal(response.body, 'hello world')

  server:close()
end)

loop.run(function()
  local server = http.listen('127.0.0.1', 7000, function(request)
    expect.equal(request.method, 'POST')
    return { status = 200 }
  end)

  for i = 1, 10 do
    local response = http.request {
      url = 'http://127.0.0.1:7000/?a=1&b=2',
      method = 'post', body = 'b=3&c=4',
    }
    collectgarbage()
  end
  collectgarbage()

  server:close()
end)

-- loop.run(function()
--   local response = http.request{
--     url = 'http://pygments.appspot.com/',
--     method = 'post', body = 'lang=lua&code=print',
--   }
-- end)

--------------------------------------------------------------------------------
-- manually invoked event loop
--------------------------------------------------------------------------------

do
  local server, response

  join(coroutine.create(function()
    server = http.listen('127.0.0.1', 7000, function(request)
      return { status = 200, body = 'ok' }
    end)
  end))

  join(coroutine.create(function()
    response = http.request { url = 'http://127.0.0.1:7000/' }
    server:close()
  end))
  
  loop.run()

  expect.equal(response.body, 'ok')
end

--------------------------------------------------------------------------------
-- dates
--------------------------------------------------------------------------------

do
  expect.equal(http.format_date(1408986974LL), 'Mon, 25 Aug 2014 17:16:14 GMT')
  -- expect.equal(http.parse_date('Mon, 25 Aug 2014 17:16:14 GMT'), 1408986974LL)

  expect.equal(http.format_date(784111777), 'Sun, 06 Nov 1994 08:49:37 GMT')
  expect.equal(http.parse_date('Sun, 06 Nov 1994 08:49:37 GMT'), 784111777)
  expect.equal(http.parse_date('Sunday, 06-Nov-94 08:49:37 GMT'), 784111777)
  expect.equal(http.parse_date('Sun Nov  6 08:49:37 1994'), 784111777)
  expect.equal(http.parse_date('asdf'), nil)
end
