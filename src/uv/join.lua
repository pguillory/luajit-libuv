local function join(thread, ...)
  local ok, err = coroutine.resume(thread, ...)
  if not ok then
    return error(debug.traceback(thread, err), 0)
  end
end

return join
