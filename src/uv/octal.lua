local function octal(s)
  local i = 0
  for c in s:gmatch('.') do
    i = i * 8 + tonumber(c)
  end
  return i
end

do
  assert(octal('0') == 0)
  assert(octal('1') == 1)
  assert(octal('10') == 8)
  assert(octal('11') == 9)
  assert(octal('100') == 64)
  assert(octal('101') == 65)
end

return octal
