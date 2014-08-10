local octal = require 'uv/octal'

--------------------------------------------------------------------------------
-- mode_atoi
--------------------------------------------------------------------------------

local mode_atoi = setmetatable({}, { __index = function(self, s)
  local i
  if type(s) == 'string' then
    if #s == 3 then
      i = octal(s)
    elseif #s == 9 then
      i = 0
      local function match_char(index, expected_char, n)
        local char = s:sub(index, index)
        if char == expected_char then
          i = i + n
        elseif char ~= '-' then
          error('file modes look like: "755" or "rwxr-xr-x"')
        end
      end
      match_char(1, 'r', 256)
      match_char(2, 'w', 128)
      match_char(3, 'x', 64)
      match_char(4, 'r', 32)
      match_char(5, 'w', 16)
      match_char(6, 'x', 8)
      match_char(7, 'r', 4)
      match_char(8, 'w', 2)
      match_char(9, 'x', 1)
    else
      error('file modes look like: "755" or "rwxr-xr-x"')
    end
  elseif type(s) == 'number' then
    i = s
  else
    error('unexpected mode type: ' .. type(s))
  end
  self[s] = i
  return i
end})

do
  assert(mode_atoi['001'] == 1)
  assert(mode_atoi['007'] == 7)
  assert(mode_atoi['070'] == 7 * 8)
  assert(mode_atoi['700'] == 7 * 64)
  assert(mode_atoi['777'] == 511)

  assert(mode_atoi['--------x'] == 1)
  assert(mode_atoi['-------w-'] == 2)
  assert(mode_atoi['------r--'] == 4)
  assert(mode_atoi['-----x---'] == 8)
  assert(mode_atoi['----w----'] == 16)
  assert(mode_atoi['---r-----'] == 32)
  assert(mode_atoi['--x------'] == 64)
  assert(mode_atoi['-w-------'] == 128)
  assert(mode_atoi['r--------'] == 256)
  assert(mode_atoi['rwxrwxrwx'] == 511)

  assert(mode_atoi[1] == 1)
  assert(mode_atoi[511] == 511)

  do
    local ok, err = pcall(function() return mode_atoi[true] end)
    assert(not ok)
    assert(err:find('unexpected mode type: boolean'))
  end
end

return mode_atoi
