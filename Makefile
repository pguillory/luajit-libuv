LUA = luajit

all: uv.min.h http_parser.min.h

################################################################################
# libuv
################################################################################

uv.min.h: libuv.a
	gcc -E libuv/include/uv.h | grep -v '^ *#' > uv.min.h

libuv.a: libuv/.libs
	cp -f libuv/.libs/libuv.* .

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

http_parser.min.h: libhttp_parser.dylib
	gcc -E http-parser/http_parser.h | grep -v '^ *#' > http_parser.min.h

libhttp_parser.dylib: http-parser/libhttp_parser.so.2.3
	cp http-parser/libhttp_parser.so.2.3 libhttp_parser.dylib
	cp http-parser/libhttp_parser.so.2.3 libhttp_parser.so

http-parser/libhttp_parser.so.2.3:
	cd http-parser && make library

http-parser/http_parser.h:
	git submodule init
	git submodule update

################################################################################
# etc...
################################################################################

clean:
	rm -rf libuv http-parser libuv.* libhttp_parser.* *.min.h
	mkdir libuv http-parser

test: run-tests
run-tests:
	LUA_PATH="src/?.lua;;" ${LUA} test/uv_test.lua
	LUA_PATH="src/?.lua;;" ${LUA} test/fs_test.lua
	LUA_PATH="src/?.lua;;" ${LUA} test/http_test.lua
	LUA_PATH="src/?.lua;;" ${LUA} test/timer_test.lua
	@echo All tests passing
