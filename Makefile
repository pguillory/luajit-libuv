all: libuv2.dylib uv2.min.h

libuv2.dylib:
	gcc -shared uv2.c -o libuv2.dylib -luv

uv2.min.h:
	cat uv2.h | gcc -E - | grep -v '^ *#' > uv2.min.h

clean:
	rm -f libuv2.dylib uv2.min.h
