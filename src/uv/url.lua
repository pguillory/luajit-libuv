local ffi = require 'ffi'
local libhttp_parser = require 'uv/libhttp_parser'

local url = {}

function url.parse(url, parts)
  local u = ffi.new('struct http_parser_url')
  local r = libhttp_parser.http_parser_parse_url(url, #url, 0, u)
  if r ~= 0 then return end

  local function segment(name, id)
    if bit.band(u.field_set, bit.lshift(1, id)) > 0 then
      local field = u.field_data[id]
      parts[name] = url:sub(field.off + 1, field.off + field.len)
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

return url
