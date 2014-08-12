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
-- Server
--------------------------------------------------------------------------------

local Server = class(function(tcp)
  return { tcp = tcp }
end)

function Server:bind(ip, port)
  self.tcp:bind(ip, port)
end

function Server:close()
  self.tcp:close()
end

function Server:listen(callback)
  self.tcp:listen(function(stream)
    local settings = ffi.new('http_parser_settings')

    local request = {
      url = '',
      status = '',
      headers = {},
      body = '',
      socket = ffi.cast('uv_tcp_t*', stream),
    }

    local header_last
    local header_field
    local header_value
    local message_complete

    settings.on_url = function(parser, buf, length)
      request.url = request.url .. ffi.string(buf, length)
      return 0
    end

    settings.on_header_field = function(parser, buf, length)
      if header_last == 'field' then
        header_field = header_field .. ffi.string(buf, length)
      elseif header_last == 'value' then
        request.headers[header_field] = header_value
        header_field = ffi.string(buf, length)
      else
        header_field = ffi.string(buf, length)
      end
      header_last = 'field'
      return 0
    end

    settings.on_header_value = function(parser, buf, length)
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

    settings.on_headers_complete = function(parser)
      if header_last == 'value' then
        request.headers[header_field] = header_value
      end
      return 0
    end

    settings.on_body = function(parser, buf, length)
      request.body = request.body .. ffi.string(buf, length)
      return 0
    end

    settings.on_message_complete = function(parser)
      request.method = ffi.string(libhttp_parser.http_method_str(parser.method))
      message_complete = true
      return 0
    end

    local parser = ffi.new('http_parser')
    libhttp_parser.http_parser_init(parser, libhttp_parser.HTTP_REQUEST)
    -- parser.data = my_socket

    repeat
      local buf = stream:read()
      local nparsed = libhttp_parser.http_parser_execute(parser, settings, buf, #buf)
    until message_complete

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
  local server = http.server(uv.loop)
  server:bind(host, port)
  server:listen(callback)
  return server
end

return http
