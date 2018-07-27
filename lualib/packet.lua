local core = require "packet.core"
local M = {}
function M.pack(opcode, server_sn, client_sn, crypt_type, crypt_key, buff, sz)
    local total = sz + 10
    local data = core.new(total)
    data:write_ushort(total)
    data:write_ushort(opcode)
    data:write_ushort(server_sn)
    data:write_ushort(client_sn)
    data:write_ubyte(crypt_type)
    data:write_ubyte(crypt_key)
    data:write_bytes(buff, sz)
    return data:pack() -- sock_sz, sock_buff
end
function M.unpack(sock_buff, sock_sz)
    local data      = core.new(sock_sz, sock_buff) 
    local total     = data:read_ushort()
    local opcode    = data:read_ushort()
    local server_sn = data:read_ushort()
    local client_sn = data:read_ushort()
    local crypt_type= data:read_ubyte()
    local crypt_key = data:read_ubyte()
    local sz        = total - 10
    local buff      = data:read_bytes(sz)
    return opcode, server_sn, client_sn, crypt_type, crypt_key, buff, sz
end
return M
