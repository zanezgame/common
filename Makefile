SRC_DIR = ./lualib-src
LIB_DIR = ./luaclib

SRC = ${wildcard ${SRC_DIR}/*.c}
LIB = ${patsubst lua-%.c, ${LIB_DIR}/%.so, ${notdir ${SRC}}}

all:${LIB}

${LIB_DIR}/%.so:${SRC_DIR}/lua-%.c
	cc -g -O2 -Wall -Iskynet/3rd/lua -fPIC --shared $< -o $@ -lcurl

.PHONY:clean
clean:
	rm ${LIB}
