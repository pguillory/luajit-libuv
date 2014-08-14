local class = require 'uv/class'
local ffi = require 'ffi'
local libhttp_parser = require 'uv/libhttp_parser'
local uv = require 'uv'

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
-- parse_url
--------------------------------------------------------------------------------

local function parse_url(request)
  local u = ffi.new('struct http_parser_url')
  local r = libhttp_parser.http_parser_parse_url(request.url, #request.url, 0, u)
  if r ~= 0 then return end

  local function segment(name, id)
    if bit.band(u.field_set, bit.lshift(1, id)) > 0 then
      local field = u.field_data[id]
      request[name] = request.url:sub(field.off + 1, field.off + field.len)
    end
  end

  segment('schema', libhttp_parser.UF_SCHEMA)
  segment('host', libhttp_parser.UF_HOST)
  segment('port', libhttp_parser.UF_PORT)
  segment('path', libhttp_parser.UF_PATH)
  segment('query', libhttp_parser.UF_QUERY)
  segment('fragment', libhttp_parser.UF_FRAGMENT)
  segment('userinfo', libhttp_parser.UF_USERINFO)
end

do
  local r = { url = 'http://127.0.0.1:7000/path/to/route?a=1&b=2#fragment' }
  parse_url(r)
  assert(r.schema == 'http')
  assert(r.host == '127.0.0.1')
  assert(r.port == '7000')
  assert(r.path == '/path/to/route')
  assert(r.query == 'a=1&b=2')
  assert(r.fragment == 'fragment')
end

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
-- Server
--------------------------------------------------------------------------------

local Server = class(function(tcp)
  return { tcp = tcp }
end)

function Server:bind(host, port)
  self.tcp:bind(host, port)
end

function Server:close()
  self.tcp:close()
end

function Server:listen(callback)
  self.tcp:listen(function(stream)
    local request = parse_http(stream, libhttp_parser.HTTP_REQUEST)

    parse_url(request)
    request.socket = ffi.cast('uv_tcp_t*', stream)

    local status, headers, body = callback(request)

    stream:write('HTTP/1.1 ' .. status .. ' ' .. status_codes[status] .. '\n')
    stream:write('Server: luajit-libuv\n')
    for field, value in pairs(headers) do
      stream:write(field .. ': ' .. value .. '\n')
    end
    stream:write('Content-Length: ' .. #body .. '\n\n')
    stream:write(body)
    stream:close()
  end)
end

--------------------------------------------------------------------------------
-- Server
--------------------------------------------------------------------------------

local http = {}

function http.server()
  return Server(uv.tcp())
end

function http.listen(host, port, callback)
  local server = http.server()
  server:bind(host, port)
  server:listen(callback)
  return server
end

function http.request(request)
  if request.url then
    parse_url(request)
  end

  local method = request.method or 'GET'
  local host = request.host or error('host required', 2)
  local port = request.port or 80
  local path = request.path or '/?'
  local query = request.query or ''
  local headers = request.headers or {}
  local body = request.body or ''

  local client = uv.tcp():connect(host, tonumber(port)).handle
  client:write(method:upper() .. ' ' .. path .. '?' .. query .. ' HTTP/1.1\n')
  client:write('Host: ' .. host .. '\n')
  client:write('User-Agent: luajit-libuv\n')
  for header, value in pairs(headers) do
    client:write(header .. ': ' .. value .. '\n')
  end
  client:write('Content-Length: ' .. #body .. '\n\n')
  client:write(body)

  local response = parse_http(client, libhttp_parser.HTTP_RESPONSE)

  client:close()

  return response
end

return http
