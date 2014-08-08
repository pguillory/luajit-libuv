#include <uv.h>

//  typedef void (*uv_read_cb)(uv_stream_t* stream, ssize_t nread, uv_buf_t buf);
typedef void (*lua_uv_read_cb)(uv_stream_t* stream, ssize_t nread, char* buf_base, size_t buf_len);

void lua_uv_read(uv_stream_t* stream, ssize_t nread, uv_buf_t buf);

//  int uv_read_start(uv_stream_t*, uv_alloc_cb alloc_cb, uv_read_cb read_cb);
int lua_uv_read_start(uv_stream_t*, uv_alloc_cb alloc_cb, lua_uv_read_cb read_cb);
uv_buf_t lua_uv_alloc(uv_handle_t* handle, size_t suggested_size);
