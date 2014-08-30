API Reference - uv.url
======================

The `url` module provides functions for working with URLs.

### url.split(str)

Return a URL's components as a table. The table may contain any of the
following keys, depending on which are present in the URL:

- `scheme`
- `userinfo`
- `host`
- `port`
- `path`
- `query`
- `fragment`

```lua
local parts = url.split 'http://myname:12345@host.com:80/path?a=1&b=2#section

-- parts.scheme == 'http'
-- parts.userinfo == 'myname:12345'
-- parts.host == 'host.com'
-- parts.port == '80'
-- parts.path == '/path'
-- parts.query == 'a=1&b=2'
-- parts.fragment == 'section'
```

### url.join(parts)

The inverse of `url.split`. It takes a table of URL components and returns the
assembled URL as a string.

```lua
url.join { path = '/path', query = 'a=1&b=2' }
-- '/path?a=1&b=2'
```

### url.encode(value)

Encode a value as a URI component. If `value` is a table, `url.encode` will return a full query string.

```lua
local query = url.encode { name = 'Isaac Newton' }
-- query == 'name=Isaac%20Newton'
```

### url.relative(base, relative)

Evaluate a relative URL in the context of a base URL. It mirrors the logic
applied by browsers when evaluating a link in a web page.

```lua
url.relative('http://host.com/path/to/page', 'other/page')
-- 'http://host.com/path/to/other/page'
```
