SKYNET = skynet/skynet
SRC_DIR = ./lualib-src
LIB_DIR = ./luaclib

all:${LIB_DIR}/webclient.so
	

${LIB_DIR}/webclient.so:${SRC_DIR}/webclient.c
	cc -g -O2 -Wall -Iskynet/3rd/lua -fPIC --shared ${SRC_DIR}/webclient.c -o ${LIB_DIR}/webclient.so -lcurl

.PHONY:clean
clean:
	rm ${LIB_DIR}/webclient.so
