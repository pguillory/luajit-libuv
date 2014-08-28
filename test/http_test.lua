require 'uv/strict'
local uv = require 'uv'
local http = require 'uv.http'
local join = require 'uv/join'

--------------------------------------------------------------------------------
-- basic server
--------------------------------------------------------------------------------

uv.run(function()
  local server = http.listen('127.0.0.1', 7000, function(request)
    assert(request.method == 'GET')
    assert(request.path == '/path/to/route')
    assert(request.query == 'a=1&b=2')
    assert(request.headers['User-Agent'] == 'test')
    return 200, { Expires = '-1' }, 'hello world'
  end)

  local response = http.request{
    url = 'http://127.0.0.1:7000/path/to/route?a=1&b=2',
    headers = { ['User-Agent'] = 'test' },
  }

  assert(response.status == 200)
  assert(response.headers['Expires'] == '-1')
  assert(response.headers['Content-Length'] == '11')
  assert(response.body == 'hello world')

  local response = http.request{
    host = '127.0.0.1', port = 7000, path = '/path/to/route', query = 'a=1&b=2',
    headers = { ['User-Agent'] = 'test' },
  }

  assert(response.status == 200)
  assert(response.headers['Expires'] == '-1')
  assert(response.headers['Content-Length'] == '11')
  assert(response.body == 'hello world')

  server:close()
end)

uv.run(function()
  local server = http.listen('127.0.0.1', 7000, function(request)
    assert(request.method == 'POST')
    return 200, {}, ''
  end)

  for i = 1, 10 do
    local response = http.request{
      url = 'http://127.0.0.1:7000/?a=1&b=2',
      method = 'post', body = 'b=3&c=4',
    }
    collectgarbage()
  end
  collectgarbage()

  server:close()
end)

-- uv.run(function()
--   local response = http.request{
--     url = 'http://pygments.appspot.com/',
--     method = 'post', body = 'lang=lua&code=print',
--   }
-- end)

--------------------------------------------------------------------------------
-- middleware pattern
--------------------------------------------------------------------------------

uv.run(function()
  local access_log = ''

  local function with_logging(yield)
    return function(request)
      local status, headers, body = yield(request)

      access_log = access_log .. string.format('%s - - [%s] "%s %s" %s %i %q %q\n',
          request.socket:getpeername(),
          '1999-12-31T23:59:59Z', -- os.date("!%Y-%m-%dT%TZ"),
          request.method,
          request.url,
          status,
          #body,
          request.headers['Referer'] or '-',
          request.headers['User-Agent'] or '-')

      return status, headers, body
    end
  end

  local server = http.listen('127.0.0.1', 7000, with_logging(function(request)
    return 200, {}, 'hello world'
  end))

  http.request { host = '127.0.0.1', port = 7000 }

  assert(access_log == '127.0.0.1 - - [1999-12-31T23:59:59Z] "GET /?" 200 11 "-" "luajit-libuv"\n')

  server:close()
end)

--------------------------------------------------------------------------------
-- manually invoked event loop
--------------------------------------------------------------------------------

do
  local server, response

  join(coroutine.create(function()
    server = http.listen('127.0.0.1', 7000, function(request)
      return 200, {}, 'ok'
    end)
  end))

  join(coroutine.create(function()
    response = http.request { url = 'http://127.0.0.1:7000/' }
    server:close()
  end))
  
  uv.run()

  assert(response.body == 'ok')
end

--------------------------------------------------------------------------------
-- dates
--------------------------------------------------------------------------------

do
  local time = 1408986974LL
  assert(http.format_date(time) == 'Mon, 25 Aug 2014 17:16:14 GMT')

  assert(http.parse_date('Sun, 06 Nov 1994 08:49:37 GMT') == 784111777)
  assert(http.parse_date('Sunday, 06-Nov-94 08:49:37 GMT') == 784111777)
  assert(http.parse_date('Sun Nov  6 08:49:37 1994') == 784111777)
  assert(http.parse_date('asdf') == nil)
end
