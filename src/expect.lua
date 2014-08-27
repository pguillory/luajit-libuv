
local expect = {}

local tosource = function(value)
  if type(value) == 'string' then
    return string.format('%q', value)
  else
    return tostring(value)
  end
end

function expect.equal(a, b)
  if a ~= b then
    local err = string.format('values should be equal:\n- %s\n- %s', tosource(a), tosource(b))
    -- print(err)
    error(err, 2)
  end
end

function expect.error(expected, callback)
  local ok, actual = pcall(callback)
  if ok then
    local err = string.format('expected an error but got none:\n- %q', expected)
    -- print(err)
    error(err, 2)
  end
  if not actual:find(expected, 1, true) then
    local err = string.format('expected a different error:\n- (expect): %q\n- (actual): %q', expected, actual)
    -- print(err)
    error(err, 2)
  end
end

function expect.ok(callback)
  local ok, actual = pcall(callback)
  if not ok then
    local err = string.format('expected no errors but got one:\n- %q', actual)
    -- print(err)
    error(err, 2)
  end
end

do
  expect.error('values should be equal', function()
    expect.equal('asdf', 'zxcv')
  end)

  expect.error('expected an error but got none', function()
    expect.error('something', function()
    end)
  end)

  expect.error('expected a different error', function()
    expect.error('something', function()
      error('anything else')
    end)
  end)

  expect.ok(function()
    expect.ok(function()
    end)
  end)

  expect.error('expected no errors but got one', function()
    expect.ok(function()
      error('something')
    end)
  end)
end

return expect
