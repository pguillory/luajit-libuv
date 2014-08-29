#include <stdlib.h>
#include "../../deps/libuv/include/uv.h"
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

int uv2_tcp_listen(uv_tcp_t* stream, int backlog, uv_connection_cb cb) {
  return uv_listen((uv_stream_t*) stream, backlog, cb);
}

int uv2_cwd(uv_buf_t* buf) {
  return uv_cwd(buf->base, &buf->len);
}

int uv2_fs_open(uv_loop_t* loop, uv_fs_t* req, const char* path, int flags, int mode, uv_fs_cb cb) {
  int flags2 = 0;

  if (flags & 0x0000) flags2 += O_RDONLY;
  if (flags & 0x0001) flags2 += O_WRONLY;
  if (flags & 0x0002) flags2 += O_RDWR;
  //if (flags & 0x0004) flags2 += O_NONBLOCK;
  if (flags & 0x0008) flags2 += O_APPEND;
  //if (flags & 0x0010) flags2 += O_SHLOCK;
  //if (flags & 0x0020) flags2 += O_EXLOCK;
  //if (flags & 0x0040) flags2 += O_ASYNC;
  //if (flags & 0x0100) flags2 += O_NOFOLLOW;
  if (flags & 0x0200) flags2 += O_CREAT;
  if (flags & 0x0400) flags2 += O_TRUNC;
  //if (flags & 0x0800) flags2 += O_EXCL;

  return uv_fs_open(loop, req, path, flags2, mode, cb);
}

int uv2_exepath(uv_buf_t* buffer) {
  return uv_exepath(buffer->base, &buffer->len);
}

int uv2_sigkill() {
  return SIGKILL;
}

int uv2_sighup() {
  return SIGHUP;
}

int uv2_sigint() {
  return SIGINT;
}

int uv2_sigwinch() {
  return SIGWINCH;
}
