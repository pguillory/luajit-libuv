all: libuv.dylib uv.min.h

libuv.dylib: libuv/Makefile
	cd libuv && make
	cp libuv/.libs/libuv.dylib .

libuv/Makefile: libuv/configure
	cd libuv && ./configure

libuv/configure: libuv/include
	cd libuv && sh autogen.sh

uv.min.h: libuv/include
	cat libuv/include/uv.h | gcc -E - | grep -v '^ *#' > uv.min.h

libuv/include:
	git submodule init
	git submodule update
	cd libuv && git checkout v0.11.28

clean:
	rm -rf libuv *.dylib *.min.h
	mkdir libuv

test: run-tests
run-tests:
	@LUA_PATH="src/?.lua;;" luajit test/uv_test.lua
	@LUA_PATH="src/?.lua;;" luajit test/fs_test.lua
	@echo All tests passing
