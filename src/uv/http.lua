require 'uv/ctypes/init'
local class = require 'uv/util/class'
local ffi = require 'ffi'
local libuv = require 'uv/libuv'
local libuv2 = require 'uv/libuv2'
local libhttp_parser = require 'uv/libhttp_parser'
local uv_tcp_t = require 'uv/ctypes/uv_tcp_t'
local url = require 'uv.url'
local join = require 'uv/util/join'

--------------------------------------------------------------------------------
-- status_codes
--------------------------------------------------------------------------------

local status_codes = {}
for i = 100, 199 do status_codes[i] = 'Informational' end
for i = 200, 299 do status_codes[i] = 'Successful' end
for i = 300, 399 do status_codes[i] = 'Redirection' end
for i = 400, 499 do status_codes[i] = 'Client Error' end
for i = 500, 599 do status_codes[i] = 'Successful' end
status_codes[100] = 'Continue'
status_codes[101] = 'Switching Protocols'
status_codes[200] = 'OK'
status_codes[201] = 'Created'
status_codes[202] = 'Accepted'
status_codes[203] = 'Non-Authoritative Information'
status_codes[204] = 'No Content'
status_codes[205] = 'Reset Content'
status_codes[206] = 'Partial Content'
status_codes[300] = 'Multiple Choices'
status_codes[301] = 'Moved Permanently'
status_codes[302] = 'Found'
status_codes[303] = 'See Other'
status_codes[304] = 'Not Modified'
status_codes[305] = 'Use Proxy'
status_codes[306] = '(Unused)'
status_codes[307] = 'Temporary Redirect'
status_codes[400] = 'Bad Request'
status_codes[401] = 'Unauthorized'
status_codes[402] = 'Payment Required'
status_codes[403] = 'Forbidden'
status_codes[404] = 'Not Found'
status_codes[405] = 'Method Not Allowed'
status_codes[406] = 'Not Acceptable'
status_codes[407] = 'Proxy Authentication Required'
status_codes[408] = 'Request Timeout'
status_codes[409] = 'Conflict'
status_codes[410] = 'Gone'
status_codes[411] = 'Length Required'
status_codes[412] = 'Precondition Failed'
status_codes[413] = 'Request Entity Too Large'
status_codes[414] = 'Request-URI Too Long'
status_codes[415] = 'Unsupported Media Type'
status_codes[416] = 'Requested Range Not Satisfiable'
status_codes[417] = 'Expectation Failed'
status_codes[500] = 'Internal Server Error'
status_codes[501] = 'Not Implemented'
status_codes[502] = 'Bad Gateway'
status_codes[503] = 'Service Unavailable'
status_codes[504] = 'Gateway Timeout'
status_codes[505] = 'HTTP Version Not Supported'

--------------------------------------------------------------------------------
-- parse_http
--------------------------------------------------------------------------------

local function parse_http(stream, mode)
  local header_last, header_field, header_value, message_complete
  local headers, body, url = {}, ''

  local on = {}

  function on:url(buf, length)
    url = (url or '') .. ffi.string(buf, length)
    return 0
  end

  function on:header_field(buf, length)
    if header_last == 'field' then
      header_field = header_field .. ffi.string(buf, length)
    elseif header_last == 'value' then
      headers[header_field] = header_value
      header_field = ffi.string(buf, length)
    else
      header_field = ffi.string(buf, length)
    end
    header_last = 'field'
    return 0
  end

  function on:header_value(buf, length)
    if header_last == 'field' then
      header_value = ffi.string(buf, length)
    elseif header_last == 'value' then
      header_value = header_value .. ffi.string(buf, length)
    else
      error('header value before field')
    end
    header_last = 'value'
    return 0
  end

  function on:headers_complete()
    if header_last == 'value' then
      headers[header_field] = header_value
    end
    return 0
  end

  function on:body(buf, length)
    body = body .. ffi.string(buf, length)
    return 0
  end

  function on:message_complete()
    message_complete = true
    return 0
  end

  local settings = ffi.new('http_parser_settings')

  settings.on_url              = ffi.cast('http_data_cb', on.url)
  settings.on_header_field     = ffi.cast('http_data_cb', on.header_field)
  settings.on_header_value     = ffi.cast('http_data_cb', on.header_value)
  settings.on_headers_complete = ffi.cast('http_cb',      on.headers_complete)
  settings.on_body             = ffi.cast('http_data_cb', on.body)
  settings.on_message_complete = ffi.cast('http_cb',      on.message_complete)

  local parser = ffi.new('http_parser')
  libhttp_parser.http_parser_init(parser, mode)

  repeat
    libhttp_parser.http_parser_execute(parser, settings, stream:read())
  until message_complete

  settings.on_url:free()
  settings.on_header_field:free()
  settings.on_header_value:free()
  settings.on_headers_complete:free()
  settings.on_body:free()
  settings.on_message_complete:free()

  local message = { url = url, headers = headers, body = body }

  if mode == libhttp_parser.HTTP_REQUEST then
    message.method = ffi.string(libhttp_parser.http_method_str(parser.method))
  else
    message.status = parser.status_code
  end

  return message
end

do
  local function test_stream(s)
    local r = {}
    function r:read()
      function r:read() return '', 0 end
      return s, #s
    end
    return r
  end

  local request = parse_http(test_stream('GET / HTTP/1.1\n\n'), libhttp_parser.HTTP_REQUEST)
  assert(request.method == 'GET')
  assert(request.status == nil)
  assert(request.url == '/')
  assert(request.body == '')

  local request = parse_http(test_stream('POST / HTTP/1.1\n\n'), libhttp_parser.HTTP_REQUEST)
  assert(request.method == 'POST')
end

--------------------------------------------------------------------------------
-- Connection
--------------------------------------------------------------------------------

local Connection = class(function(socket)
  return { socket = socket }
end)

function Connection:receive()
  local request = parse_http(self.socket, libhttp_parser.HTTP_REQUEST)
  url.split(request.url, request)
  request.ip = ffi.cast('uv_tcp_t*', self.socket):getpeername()
  return request
end

function Connection:respond(response)
  self.socket:write('HTTP/1.1 ' .. response.status .. ' ' .. status_codes[response.status] .. '\n')

  response.headers = response.headers or {}

  if not response.headers['Server'] then
    response.headers['Server'] = 'luajit-libuv'
  end

  response.headers['Content-Length'] = response.body and #response.body or 0

  for field, value in pairs(response.headers) do
    self.socket:write(field .. ': ' .. value .. '\n')
  end

  self.socket:write('\n')

  if response.body then
    self.socket:write(response.body)
  end
end

function Connection:close()
  return self.socket:close()
end

--------------------------------------------------------------------------------
-- Server
--------------------------------------------------------------------------------

local Server = class(function(server)
  return { server = server }
end)

function Server:accept()
  local socket = self.server:accept()
  return Connection(socket)
end

function Server:close()
  return self.server:close()
end

--------------------------------------------------------------------------------
-- http
--------------------------------------------------------------------------------

local http = {}

function http.listen(host, port, on_request, on_error)
  if on_request then
    local server = http.listen(host, port)
    join(coroutine.create(function()
      while true do
        local connection = server:accept()
        join(coroutine.create(function()
          local request = connection:receive()
          local ok, response = xpcall(function()
            return on_request(request)
          end, on_error or error)
          if ok then
            connection:respond(response)
          end
          connection:close()
        end))
      end
    end))
    if coroutine.running() then
      return server
    else
      libuv.uv_default_loop():run()
      return
    end
  end

  local server = uv_tcp_t()
  server:bind(host, port)
  server:listen()
  return Server(server)
end

function http.request(request)
  if request.url then
    url.split(request.url, request)
  end

  local method  = request.method or 'GET'
  local host    = request.host or error('host required', 2)
  local port    = request.port or 80
  local path    = request.path or '/'
  local query   = request.query or ''
  local headers = request.headers or {}
  local body    = request.body or ''

  if not headers['Host'] then
    headers['Host'] = host
  end
  if not headers['User-Agent'] then
    headers['User-Agent'] = 'luajit-libuv'
  end

  local tcp = uv_tcp_t()
  local client = tcp:connect(host, tonumber(port))
  client:write(method:upper() .. ' ' .. path .. '?' .. query .. ' HTTP/1.1\r\n')
  for header, value in pairs(headers) do
    client:write(header .. ': ' .. value .. '\r\n')
  end
  client:write('Content-Length: ' .. #body .. '\r\n\r\n')
  client:write(body)

  local response = parse_http(client, libhttp_parser.HTTP_RESPONSE)

  client:close()

  return response
end

function http.format_date(time)
  return os.date("!%a, %d %b %Y %H:%M:%S GMT", tonumber(time))
end

local month_atoi = {
  Jan = 1,
  Feb = 2,
  Mar = 3,
  Apr = 4,
  May = 5,
  Jun = 6,
  Jul = 7,
  Aug = 8,
  Sep = 9,
  Oct = 10,
  Nov = 11,
  Dec = 12,
}

local function get_timezone_offset(ts)
	local utcdate   = os.date("!*t", ts)
	local localdate = os.date("*t", ts)
	localdate.isdst = false -- this is the trick
	return os.difftime(os.time(localdate), os.time(utcdate))
end

function http.parse_date(s)
  local rfc1123 = '%w+, (%d+) (%w+) (%d+) (%d+):(%d+):(%d+) GMT' -- Sun, 06 Nov 1994 08:49:37 GMT
  local rfc1036 = '%w+, (%d+)-(%w+)-(%d+) (%d+):(%d+):(%d+) GMT' -- Sunday, 06-Nov-94 08:49:37 GMT
  local asctime = '%w+ (%w+) +(%d+) (%d+):(%d+):(%d+) (%d+)' -- Sun Nov  6 08:49:37 1994

  local day, month, year, hour, min, sec

  day, month, year, hour, min, sec = s:match(rfc1123)
  if day then
    -- print('RFC 1123: ' .. s)
  else
    day, month, year, hour, min, sec = s:match(rfc1036)
    if day then
      -- print('RFC 1036: ' .. s)
      if tonumber(year) >= 0 then
        year = '19' .. year
      else
        year = '20' .. year
      end
    else
      month, day, hour, min, sec, year = s:match(asctime)
      if day then
        -- print('asctime: ' .. s)
      else
        return
      end
    end
  end

  local time = os.time {
    year = tonumber(year),
    month = assert(month_atoi[month], 'invalid month'),
    day = tonumber(day),
    hour = tonumber(hour),
    min = tonumber(min),
    sec = tonumber(sec),
    isdst = false,
  }
  return time + get_timezone_offset(time)
end

return http
