API Reference - uv.system
=========================

The `system` module provides functionality related to the system as a whole,
not just this process.

### system.free_memory()

Returns the amount of free memory available to the system, in bytes.

### system.total_memory()

Returns the total amount of memory in the system, in bytes.

### system.hrtime()

Returns a high-resolution time in nanoseconds. It is useful for measuring
intervals but not for determining the current clock time.

### system.loadavg()

Returns the system load average over 1, 5, and 15 minutes. The load average is
the average number of jobs in the run queue.

### system.uptime()

Returns the number of seconds since the system booted.
