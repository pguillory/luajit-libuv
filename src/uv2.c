#include <stdlib.h>
#include "uv2.h"

// Luajit's FFI does not handle callbacks with a pass-by-value struct as an
// argument or return value. There are two libuv callback types for which this
// causes problems, and they have two different workarounds.
// 
// * For uv_read_cb, we create an alternative callback type that accepts the
//   uv_buf_t's `base` and `size` fields as two separate arguments. Then we use a
//   wrapper to store and retrieve our custom callback from the req's `data`
//   field.
// 
// * For uv_alloc_cb, we give up the implied generality and pass a generic
//   allocator that uses malloc.

void lua_uv_read(uv_stream_t* stream, ssize_t nread, uv_buf_t buf) {
  lua_uv_read_cb read_cb = (lua_uv_read_cb) stream->data;
  read_cb(stream, nread, buf.base, buf.len);
}

int lua_uv_read_start(uv_stream_t* stream, uv_alloc_cb alloc_cb, lua_uv_read_cb read_cb) {
  stream->data = (void*) read_cb;
  return uv_read_start(stream, alloc_cb, lua_uv_read);
}

uv_buf_t lua_uv_alloc(uv_handle_t* handle, size_t suggested_size) {
  uv_buf_t buf;
  buf.base = malloc(suggested_size);
  buf.len = suggested_size;
  return buf;
}
