all: uv.min.h http_parser.min.h

################################################################################
# libuv
################################################################################

uv.min.h: libuv.dylib
	cat libuv/include/uv.h | gcc -E - | grep -v '^ *#' > uv.min.h

libuv.dylib: libuv/Makefile
	cd libuv && make
	cp libuv/.libs/libuv.dylib .

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
	cat http-parser/http_parser.h | gcc -E - | grep -v '^ *#' | tail +344 > http_parser.min.h

libhttp_parser.dylib: http-parser/libhttp_parser.so.2.3
	cp http-parser/libhttp_parser.so.2.3 libhttp_parser.dylib

http-parser/libhttp_parser.so.2.3:
	cd http-parser && make library

http-parser/http_parser.h:
	git submodule init
	git submodule update

################################################################################
# etc...
################################################################################

clean:
	rm -rf libuv http-parser *.dylib *.min.h
	mkdir libuv http-parser

test: run-tests
run-tests:
	@LUA_PATH="src/?.lua;;" luajit test/uv_test.lua
	@LUA_PATH="src/?.lua;;" luajit test/fs_test.lua
	@LUA_PATH="src/?.lua;;" luajit test/http_test.lua
	@echo All tests passing
