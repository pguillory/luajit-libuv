LUA = luajit
LUA_DIR=/usr/local
LUA_LIBDIR=$(LUA_DIR)/lib/lua/5.1
LUA_SHAREDIR=$(LUA_DIR)/share/lua/5.1

all: src/uv/lib/libuv.min.h src/uv/lib/libhttp_parser.min.h

################################################################################
# libuv
################################################################################

libuv/include/uv.h:
	git submodule init
	git submodule update

libuv/configure: libuv/include/uv.h
	cd libuv && sh autogen.sh

libuv/Makefile: libuv/configure
	cd libuv && ./configure

libuv/.libs: libuv/Makefile
	cd libuv && make

src/uv/lib/libuv.a: libuv/.libs
	cp -f libuv/.libs/libuv.* src/uv/lib/

src/uv/lib/libuv.min.h: src/uv/lib/libuv.a
	gcc -E libuv/include/uv.h | grep -v '^ *#' > src/uv/lib/libuv.min.h

################################################################################
# http-parser
################################################################################

http-parser/http_parser.h:
	git submodule init
	git submodule update

http-parser/libhttp_parser.so.2.3:
	cd http-parser && make library

src/uv/lib/libhttp_parser.dylib: http-parser/libhttp_parser.so.2.3
	cp http-parser/libhttp_parser.so.2.3 src/uv/lib/libhttp_parser.dylib
	cp http-parser/libhttp_parser.so.2.3 src/uv/lib/libhttp_parser.so

src/uv/lib/libhttp_parser.min.h: src/uv/lib/libhttp_parser.dylib
	gcc -E http-parser/http_parser.h | grep -v '^ *#' > src/uv/lib/libhttp_parser.min.h

################################################################################
# etc...
################################################################################

install: all
	cp -R src/uv ${LUA_SHAREDIR}/

clean:
	rm -rf libuv http-parser src/uv/lib
	mkdir libuv http-parser src/uv/lib

test: run-tests
run-tests:
	LUA_PATH="src/?.lua;;" ${LUA} test/uv_test.lua
	LUA_PATH="src/?.lua;;" ${LUA} test/fs_test.lua
	LUA_PATH="src/?.lua;;" ${LUA} test/http_test.lua
	LUA_PATH="src/?.lua;;" ${LUA} test/timer_test.lua
	@echo All tests passing
