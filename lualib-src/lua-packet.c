//
// $id: packet.c zhongfq $
//

#include "lua.h"
#include "lauxlib.h"

#include <stdlib.h>
#include <stdint.h>
#include <string.h>

static int _pack(lua_State *L)
{
    char *buffer;
    char *content;
    int type = luaL_checkinteger(L, 1);
    int sn = luaL_checkinteger(L, 2);
    const char *data = (const char *)lua_touserdata(L, 3);
    int datalen = luaL_checkinteger(L, 4);
    
    int total = 8 + datalen; // len(2) + type(2) + sn(4) + datalen
    
    if (total > UINT16_MAX) {
        lua_pushfstring(L, "packet to large: type=%d sn=%d datalen=%d", type, sn, datalen);
        lua_error(L);
    }
    
    buffer = (char *)malloc(total);
    content = buffer;
    
    // len
    *content++ = total >> 8 & 0xFF;
    *content++ = total & 0xFF;
    
    // type
    *content++ = type >> 8 & 0xFF;
    *content++ = type & 0xFF;

    // sn
    *content++ = sn >> 24 & 0xFF;
    *content++ = sn >> 16 & 0xFF;
    *content++ = sn >> 8 & 0xFF;
    *content++ = sn & 0xFF;

    memcpy(content, data, datalen);
    
    lua_pushlightuserdata(L, buffer);
    lua_pushinteger(L, total);
    
    return 2;
}

static int _unpack(lua_State *L)
{
    int type, sn;
    uint8_t *buffer = (uint8_t *)lua_touserdata(L, 1);
    int len = luaL_checkinteger(L, 2);
    
    if (len < 6) {
        lua_pushfstring(L, "packet to small: len=%d", len);
        lua_error(L);
    }
    
    type = (int)buffer[0] << 8 | (int)buffer[1];
    sn = (int)buffer[2] << 24 | (int)buffer[3] << 16 | (int)buffer[4] << 8 | (int)buffer[5];
    
    lua_pushinteger(L, type);
    lua_pushinteger(L, sn);
    lua_pushlightuserdata(L, buffer + 6);
    lua_pushinteger(L, len - 6);
    
    return 4;
}

static int _dump(lua_State *L)
{
    static char X[] = {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F'};
    int i;
    uint8_t *buffer = (uint8_t *)lua_touserdata(L, 1);
    int len = luaL_checkinteger(L, 2);
    luaL_Buffer b;
    luaL_buffinit(L, &b);
    for (i = 0; i < len; i++) {
        uint8_t c = buffer[i];
        luaL_addchar(&b, X[c >> 4 & 0xF]);
        luaL_addchar(&b, X[c & 0xF]);
    }
    luaL_pushresult(&b);
    return 1;
}

static int _droplen(lua_State *L)
{
    uint8_t *buffer = (uint8_t *)lua_touserdata(L, 1);
    int len = luaL_checkinteger(L, 2);
    
    lua_pushlightuserdata(L, buffer + 2);
    lua_pushinteger(L, len - 2);
    
    return 2;
}

LUALIB_API int luaopen_packet(lua_State *L)
{
    luaL_Reg lib[] = {
        {"pack", _pack},
        {"unpack", _unpack},
        {"droplen", _droplen},
        {"dump", _dump},
        {NULL, NULL},
    };
    luaL_checkversion(L);
    luaL_newlib(L, lib);
    
    return 1;
}
