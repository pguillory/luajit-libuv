#include <stdlib.h>
#include "../../libuv/include/uv.h"
#include "libuv2.h"

void uv2_alloc_cb(uv_handle_t* handle, size_t suggested_size, uv_buf_t* buf) {
  buf->base = malloc(suggested_size);
  buf->len = suggested_size;
}

void uv2_stream_close(uv_stream_t* stream, uv_close_cb close_cb) {
  return uv_close((uv_handle_t*) stream, close_cb);
}

void uv2_tcp_close(uv_tcp_t* tcp, uv_close_cb close_cb) {
  return uv_close((uv_handle_t*) tcp, close_cb);
}

int uv2_tcp_accept(uv_tcp_t* server, uv_tcp_t* client) {
  return uv_accept((uv_stream_t*) server, (uv_stream_t*) client);
}

int uv2_tcp_read_start(uv_tcp_t* tcp, uv_alloc_cb alloc_cb, uv_read_cb read_cb) {
  return uv_read_start((uv_stream_t*) tcp, alloc_cb, read_cb);
}

int uv2_tcp_read_stop(uv_tcp_t* tcp) {
  return uv_read_stop((uv_stream_t*) tcp);
}

int uv2_tcp_write(uv_write_t* req, uv_tcp_t* tcp, const uv_buf_t bufs[], unsigned int nbufs, uv_write_cb cb) {
  return uv_write(req, (uv_stream_t*) tcp, bufs, nbufs, cb);
}

// local buf = ffi.new('uv_buf_t')
// buf.base = ffi.cast('char*', content)
// buf.len = #content
// self.loop:assert(libuv2.uv2_tcp_write(req, self, content, #content, 1, callback))

int uv2_tcp_listen(uv_tcp_t* stream, int backlog, uv_connection_cb cb) {
  return uv_listen((uv_stream_t*) stream, backlog, cb);
}
