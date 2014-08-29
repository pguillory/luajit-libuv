
void uv2_alloc_cb(uv_handle_t* handle, size_t suggested_size, uv_buf_t* buf);
void uv2_stream_close(uv_stream_t* stream, uv_close_cb close_cb);
void uv2_tcp_close(uv_tcp_t* stream, uv_close_cb close_cb);
int uv2_tcp_accept(uv_tcp_t* server, uv_tcp_t* client);
int uv2_tcp_read_start(uv_tcp_t*, uv_alloc_cb alloc_cb, uv_read_cb read_cb);
int uv2_tcp_read_stop(uv_tcp_t*);
int uv2_tcp_write(uv_write_t* req, uv_tcp_t* tcp, const uv_buf_t bufs[], unsigned int nbufs, uv_write_cb cb);
int uv2_tcp_listen(uv_tcp_t* stream, int backlog, uv_connection_cb cb);
int uv2_cwd(uv_buf_t* buf);
int uv2_fs_open(uv_loop_t* loop, uv_fs_t* req, const char* path, int flags, int mode, uv_fs_cb cb);
int uv2_exepath(uv_buf_t* buffer);
int uv2_sigkill();
int uv2_sighup();
int uv2_sigint();
int uv2_sigwinch();
