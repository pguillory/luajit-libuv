API Reference - timer
=====================

**timer.set(timeout, callback)**

Schedule a function to be called once in the future. Returns immediately.

```lua
timer.set(5000, function()
  print('Ding!')
end)
print('Waiting 5 seconds...')
uv.run()
print('The timer dinged.')
```

**timer.every(timeout, callback)**

Schedule a function to be called every `timeout` milliseconds. Returns
immediately.

```lua
timer.every(1000, function(t)
  print('Tick...')
  if we_are_done then
    t:stop()
  end
end)
uv.run()
```

**timer.sleep(timeout, callback)**

Yield the current coroutine for `timeout` milliseconds.

```lua
print('Going to sleep...')
timer.sleep(5000)
print('Woke up')
```
