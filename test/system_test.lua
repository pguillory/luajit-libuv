require 'uv/util/strict'
local system = require 'uv.system'

do
  local free, total = system.free_memory(), system.total_memory()
  assert(free > 0)
  assert(total > 0)
  assert(free <= total)
end

do
  local hrtime = system.hrtime()
  assert(hrtime > 0)
end

do
  local x, y, z = system.loadavg()
  assert(type(x) == 'number')
  assert(type(y) == 'number')
  assert(type(z) == 'number')
end

do
  local uptime = system.uptime()
  assert(uptime > 0)
end
