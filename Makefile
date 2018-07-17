SKYNET = skynet/skynet
SRC_DIR = ./lualib-src
LIB_DIR = ./luaclib

all:${SKYNET} ${LIB_DIR}/webclient.so
	
${SKYNET}:
	cd skynet && make linux

${LIB_DIR}/webclient.so:${SRC_DIR}/webclient.c
	cc -g -O2 -Wall -Iskynet/3rd/lua -fPIC --shared ${SRC_DIR}/webclient.c -o ${LIB_DIR}/webclient.so -lcurl

.PHONY:clean
clean:
	cd skynet && make clean
	cd luaclib && rm *
