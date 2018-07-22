SKYNET = skynet/skynet
SRC_DIR = ./lualib-src
LIB_DIR = ./luaclib

all:${LIB_DIR}/webclient.so ${LIB_DIR}/websocketclient.so ${LIB_DIR}/caes.so
	

${LIB_DIR}/webclient.so:${SRC_DIR}/lua-webclient.c
	cc -g -O2 -Wall -Iskynet/3rd/lua -fPIC --shared ${SRC_DIR}/lua-webclient.c -o ${LIB_DIR}/webclient.so -lcurl
${LIB_DIR}/websocketclient.so:${SRC_DIR}/lua-websocketclient.c
	cc -g -O2 -Wall -Iskynet/3rd/lua -fPIC --shared ${SRC_DIR}/lua-websocketclient.c -o ${LIB_DIR}/websocketclient.so -lcurl
${LIB_DIR}/caes.so:${SRC_DIR}/lua-aes.c
	cc -g -O2 -Wall -Iskynet/3rd/lua -fPIC --shared ${SRC_DIR}/lua-aes.c -o ${LIB_DIR}/caes.so -lcurl

.PHONY:clean
clean:
	rm ${LIB_DIR}/webclient.so ${LIB_DIR}/websocketclient.so ${LIB_DIR}/caes.so
