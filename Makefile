all: libuv2.dylib uv2.min.h

libuv2.dylib:
	gcc -shared src/uv2.c -o libuv2.dylib -luv

uv2.min.h:
	cat src/uv2.h | gcc -E - | grep -v '^ *#' > uv2.min.h

clean:
	rm -f libuv2.dylib uv2.min.h

test: run-tests
run-tests:
	@LUA_PATH="src/?.lua;;" luajit test/uv_test.lua
	@LUA_PATH="src/?.lua;;" luajit test/fs_test.lua
	@echo All tests passing
