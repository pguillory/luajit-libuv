#include <stdlib.h>
#include "uv2.h"

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
