local c = require "cpacket"
local M = {}
function M.pack(opcode, server_sn, client_sn, crypt_type, crypt_key, buff, sz)
    local total = sz + 10
    local data = c.new(total)
    data:write_ushort(total)
    data:write_ushort(opcode)
    data:write_ushort(server_sn)
    data:write_ushort(client_sn)
    data:write_ubyte(crypt_type)
    data:write_ubyte(crypt_key)
    data:write_bytes(buff)
    return data:pack()
end

function M.unpack(buff, sz)
    local data      = c.new(sz, buff) 
    local total     = data:read_ushort()
    local opcode    = data:read_ushort()
    local server_sn = data:read_ushort()
    local client_sn = data:read_ushort()
    local crypt_type= data:read_ubyte()
    local crypt_key = data:read_ubyte()
    local buff      = data:read_bytes(total-10)
    return opcode, server_sn, client_sn, crypt_type, crypt_key, buff, sz
end
return M
