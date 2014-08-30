API Reference - uv.http
=======================

The `http` module provides both a client and a server.

### http.request(request)

Send an HTTP request and return the response. `request` should be a table with
the following fields:

- `method`: An HTTP method. Defaults to 'GET'.

- `url`: The full URL to request. Any parts that are present will override the
  corresponding options below.

- `scheme`: Defaults to 'http'.

- `host`: Either an IP or DNS name is acceptable.

- `port`: Defaults to 80.

- `path`: Defaults to '/'.

- `query`: Query string. Optional.

- `body`: Request body, for POST requests.

The value returned will be a table containing the following fields:

- `status`: The HTTP status. 200 on success, or 400+ on error.

- `headers`: A table of HTTP response headers.

- `body`: The response body, as a string.

```lua
local response = http.request { url = 'http://example.com/page1' }

-- or

local response = http.request { host = 'example.com', path = '/page1' }
```

### http.listen(host, port, callback)

Listen for requests at the given host and port. Use a `host` value of
"0.0.0.0" to listen on all network interfaces, or "127.0.0.1" to only listen
for requests from your own computer.

Each request will be passed to `callback` in a distinct coroutine. The
callback should return an HTTP status, a table of response headers, and a
response body.

```lua
http.listen('127.0.0.1', 80, function(request)
  local status = 200
  local headers = { ['Content-Type'] => 'text/html' }
  local body = '<h1>Hello world!</h1>'
  return status, headers, body
end)
```

Requests are tables containing the following keys:

- `method`: An HTTP method, like 'GET' or 'POST'.
- `url`: The URL from the raw HTTP request.
- `path`: The path portion of the URL.
- `query`: The query portion of the URL, as a string.
- `headers`: The request headers, as a table.
- `body`: The request body. Only present for POST requests.

Note that the query string is not parsed. See the [url](url.md) module.

### http.format_date(time)

Format a date according to RFC 1123, which is the preferred date format in
HTTP. `time` is a number representing a [Unix time]. It defaults to the current time, given by `os.time()`.

### http.parse_date(date_string)

Parse a date string in any of the acceptable [HTTP date formats].

[HTTP date formats]: http://www.w3.org/Protocols/rfc2616/rfc2616-sec3.html#sec3.3

[Unix time]: http://en.wikipedia.org/wiki/Unix_time
