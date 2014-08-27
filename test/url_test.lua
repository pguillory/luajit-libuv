local url = require 'uv.url'

do
  local r = {}
  url.parse('http://127.0.0.1:7000/path/to/route?a=1&b=2#fragment', r)
  assert(r.schema == 'http')
  assert(r.host == '127.0.0.1')
  assert(r.port == '7000')
  assert(r.path == '/path/to/route')
  assert(r.query == 'a=1&b=2')
  assert(r.fragment == 'fragment')
end
