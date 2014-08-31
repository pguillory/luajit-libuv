require 'uv/ctypes/init'
local class = require 'uv/util/class'
local ffi = require 'ffi'
local libhttp_parser = require 'uv/libhttp_parser'

local url = {}

function url.split(s, parts)
  if s:sub(1, 2) == '//' then
    local parts = url.split('http:' .. s, parts)
    parts.schema = nil
    return parts
  end

  parts = parts or {}

  local struct = ffi.new('struct http_parser_url')
  local status = libhttp_parser.http_parser_parse_url(s, #s, 0, struct)
  if status ~= 0 then
    if s:sub(1, 1) ~= '/' then
      local parts = url.split('/' .. s, parts)
      parts.path = parts.path:sub(2)
      return parts
    end
    error('error parsing url')
  end

  local function segment(name, id)
    if bit.band(struct.field_set, bit.lshift(1, id)) > 0 then
      local field = struct.field_data[id]
      parts[name] = s:sub(field.off + 1, field.off + field.len)
    end
  end

  segment('schema',   libhttp_parser.UF_SCHEMA)
  segment('host',     libhttp_parser.UF_HOST)
  segment('port',     libhttp_parser.UF_PORT)
  segment('path',     libhttp_parser.UF_PATH)
  segment('query',    libhttp_parser.UF_QUERY)
  segment('fragment', libhttp_parser.UF_FRAGMENT)
  segment('userinfo', libhttp_parser.UF_USERINFO)

  return parts
end

function url.join(parts)
  return (parts.schema    and (parts.schema .. '://') or (parts.host and '//' or ''))
      .. (parts.userinfo  and (parts.userinfo .. '@') or '')
      .. (parts.host                                  or '')
      .. (parts.port      and (':' .. parts.port)     or '')
      .. (parts.path                                  or '')
      .. (parts.query     and ('?' .. parts.query)    or '')
      .. (parts.fragment  and ('#' .. parts.fragment) or '')
end

function url.encode(value)
  if type(value) == 'table' then
    local names = {}
    for name in pairs(value) do
      table.insert(names, name)
    end
    table.sort(names)

    local buffer = {}
    for _, name in ipairs(names) do
      table.insert(buffer, url.encode(name) .. '=' .. url.encode(value[name]))
    end
    return table.concat(buffer, '&')
  elseif type(value) == 'string' then
    return (value:gsub('[^%w]', function(c)
      return string.format('%%%02X', string.byte(c))
    end))
  elseif type(value) == 'nil' then
    return ''
  else
    return url.encode(tostring(value))
  end
end

function url.relative(base, relative)
  local base = url.split(base)
  local relative = url.split(relative)

  local result = {
    schema    = relative.schema   or base.schema,
    userinfo  = relative.userinfo or base.userinfo,
    host      = relative.host     or base.host,
    port      = relative.port     or base.port,
    path      = relative.path     or base.path,
    query     = relative.query    or base.query,
    fragment  = relative.fragment or base.fragment,
  }

  if relative.path == '' or relative.path == nil then
    result.path = base.path
  elseif relative.path:match('^/') then
    result.path = relative.path
  else
    result.path = base.path:gsub('[^/]*$', relative.path, 1)
  end

  return url.join(result)
end

return url
