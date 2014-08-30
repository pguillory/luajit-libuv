LUA = ./luajit
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

deps/libuv-v0.11.28.zip:
	wget https://github.com/joyent/libuv/archive/v0.11.28.zip -O $@

deps/libuv-0.11.28: deps/libuv-v0.11.28.zip
	rm -rf $@
	unzip $< -d deps
	touch $@

deps/libuv: deps/libuv-0.11.28
	cd deps && ln -fs libuv-0.11.28 libuv

deps/libuv/include/uv.h: deps/libuv
deps/libuv/autogen.sh: deps/libuv

deps/libuv/configure: deps/libuv/autogen.sh
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

src/uv/lib/libuv2.so: src/uv/libuv2.c deps/libuv/.libs/libuv.so
	gcc -g -fPIC -shared $+ -o $@

src/uv/lib/libuv2.min.h: src/uv/libuv2.h
	gcc -E $+ | grep -v '^ *#' > $@


################################################################################
# http-parser
################################################################################

deps/http-parser-v2.3.zip:
	wget https://github.com/joyent/http-parser/archive/v2.3.zip -O $@

deps/http-parser-2.3: deps/http-parser-v2.3.zip
	rm -rf $@
	unzip $< -d deps
	touch $@

deps/http-parser: deps/http-parser-2.3
	cd deps && ln -fs http-parser-2.3 http-parser

deps/http-parser/http_parser.h: deps/http-parser

deps/http-parser/libhttp_parser.so.2.3: deps/http-parser
	cd deps/http-parser && make library

src/uv/lib/libhttp_parser.$(EXT): deps/http-parser/libhttp_parser.so.2.3
	cp $+ $@

src/uv/lib/libhttp_parser.min.h: deps/http-parser/http_parser.h
	gcc -E $+ | grep -v '^ *#' > $@

################################################################################
# luajit
################################################################################

deps/LuaJIT-2.0.3.tar.gz:
	cd deps && wget http://luajit.org/download/LuaJIT-2.0.3.tar.gz

deps/LuaJIT-2.0.3: deps/LuaJIT-2.0.3.tar.gz
	rm -rf $@
	cd deps && tar zxf LuaJIT-2.0.3.tar.gz
	touch $@

deps/LuaJIT-2.0.3/Makefile: deps/LuaJIT-2.0.3

deps/LuaJIT-2.0.3/src/luajit: deps/LuaJIT-2.0.3/Makefile
	cd deps/LuaJIT-2.0.3 && make

luajit: deps/LuaJIT-2.0.3/src/luajit
	cp $+ $@

################################################################################
# etc...
################################################################################

install: all uninstall
	cp -R src/uv ${LUA_SHAREDIR}/

uninstall:
	rm -rf ${LUA_SHAREDIR}/uv

clean:
	rm -rf deps/* src/uv/lib/*

test: run-tests
run-tests: $(LUA)
	@LUA_PATH="src/?.lua;;" ${LUA} test/fs_test.lua
	@LUA_PATH="src/?.lua;;" ${LUA} test/http_test.lua
	@LUA_PATH="src/?.lua;;" ${LUA} test/parallel_test.lua
	@LUA_PATH="src/?.lua;;" ${LUA} test/process_test.lua
	@LUA_PATH="src/?.lua;;" ${LUA} test/system_test.lua
	@LUA_PATH="src/?.lua;;" ${LUA} test/timer_test.lua
	@LUA_PATH="src/?.lua;;" ${LUA} test/url_test.lua
	@LUA_PATH="src/?.lua;;" ${LUA} test/uv_test.lua
	@echo All tests passing
