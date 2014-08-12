LUA = luajit

all: src/uv/libuv.min.h src/uv/libhttp_parser.min.h

################################################################################
# libuv
################################################################################

src/uv/libuv.min.h: src/uv/libuv.a
	gcc -E libuv/include/uv.h | grep -v '^ *#' > src/uv/libuv.min.h

src/uv/libuv.a: libuv/.libs
	cp -f libuv/.libs/libuv.* src/uv/

libuv/.libs: libuv/Makefile
	cd libuv && make

libuv/Makefile: libuv/configure
	cd libuv && ./configure

libuv/configure: libuv/include/uv.h
	cd libuv && sh autogen.sh

libuv/include/uv.h:
	git submodule init
	git submodule update

################################################################################
# http-parser
################################################################################

src/uv/libhttp_parser.min.h: src/uv/libhttp_parser.dylib
	gcc -E http-parser/http_parser.h | grep -v '^ *#' > src/uv/libhttp_parser.min.h

src/uv/libhttp_parser.dylib: http-parser/libhttp_parser.so.2.3
	cp http-parser/libhttp_parser.so.2.3 src/uv/libhttp_parser.dylib
	cp http-parser/libhttp_parser.so.2.3 src/uv/libhttp_parser.so

http-parser/libhttp_parser.so.2.3:
	cd http-parser && make library

http-parser/http_parser.h:
	git submodule init
	git submodule update

################################################################################
# etc...
################################################################################

clean:
	find src/uv -name "libhttp_parser.*" | grep -v lua | xargs rm
	find src/uv -name "libuv.*" | grep -v lua | xargs rm
	rm -rf libuv http-parser
	mkdir libuv http-parser

test: run-tests
run-tests:
	LUA_PATH="src/?.lua;;" ${LUA} test/uv_test.lua
	LUA_PATH="src/?.lua;;" ${LUA} test/fs_test.lua
	LUA_PATH="src/?.lua;;" ${LUA} test/http_test.lua
	LUA_PATH="src/?.lua;;" ${LUA} test/timer_test.lua
	@echo All tests passing
