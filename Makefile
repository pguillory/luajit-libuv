LUA = luajit
LUA_DIR=/usr/local
LUA_LIBDIR=$(LUA_DIR)/lib/lua/5.1
LUA_SHAREDIR=$(LUA_DIR)/share/lua/5.1

EXT ?= so
ifeq ($(shell uname -s), Darwin)
	EXT = dylib
endif

FILES=src/uv/lib/libuv.$(EXT) \
	  src/uv/lib/libuv.min.h \
	  src/uv/lib/libuv2.$(EXT) \
	  src/uv/lib/libuv2.min.h \
	  src/uv/lib/libhttp_parser.$(EXT) \
	  src/uv/lib/libhttp_parser.min.h

all: $(FILES)

################################################################################
# libuv
################################################################################

deps/libuv/include/uv.h:
	git submodule init
	git submodule update

deps/libuv/configure: deps/libuv/include/uv.h
	cd deps/libuv && sh autogen.sh

deps/libuv/Makefile: deps/libuv/configure
	cd deps/libuv && ./configure

deps/libuv/.libs/libuv.a: deps/libuv/Makefile
	cd deps/libuv && make

deps/libuv/.libs/libuv.$(EXT): deps/libuv/.libs/libuv.a

src/uv/lib/libuv.$(EXT): deps/libuv/.libs/libuv.$(EXT)
	cp $+ $@

src/uv/lib/libuv.min.h: deps/libuv/include/uv.h
	gcc -E $+ | grep -v '^ *#' > $@

src/uv/lib/libuv2.dylib: deps/libuv/.libs/libuv.a src/uv/libuv2.c
	gcc -dynamiclib $+ -o $@

src/uv/lib/libuv2.so: deps/libuv/.libs/libuv.a src/uv/libuv2.c
	gcc -g -fPIC -shared $+ -o $@

src/uv/lib/libuv2.min.h: src/uv/libuv2.h
	gcc -E $+ | grep -v '^ *#' > $@


################################################################################
# http-parser
################################################################################

deps/http-parser/http_parser.h:
	git submodule init
	git submodule update

deps/http-parser/libhttp_parser.so.2.3:
	cd deps/http-parser && make library

src/uv/lib/libhttp_parser.$(EXT): deps/http-parser/libhttp_parser.so.2.3
	cp $+ $@

src/uv/lib/libhttp_parser.min.h: deps/http-parser/http_parser.h
	gcc -E $+ | grep -v '^ *#' > $@

################################################################################
# etc...
################################################################################

install: all
	cp -R src/uv ${LUA_SHAREDIR}/

clean:
	rm -rf deps/* src/uv/lib/*

test: run-tests
run-tests:
	@LUA_PATH="src/?.lua;;" ${LUA} test/uv_test.lua
	@LUA_PATH="src/?.lua;;" ${LUA} test/fs_test.lua
	@LUA_PATH="src/?.lua;;" ${LUA} test/http_test.lua
	@LUA_PATH="src/?.lua;;" ${LUA} test/timer_test.lua
	@echo All tests passing
