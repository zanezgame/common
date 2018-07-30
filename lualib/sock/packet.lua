local core = require "packet.core"

-- op 协议号
-- csn 客户端session
-- ssn 服务器session
-- crypt_type 加密类型
-- crypt_key 加密key sn
-- buff sz 要发送的数据和长度
-- sock_buff sock_sz 缓冲区的数据和长度

local HEADER_SIZE = 10

local M = {}
function M.pack(opcode, csn, ssn, crypt_type, crypt_key, buff, sz)
    local total = sz + HEADER_SIZE
    local data = core.new(total)
    data:write_ushort(total)
    data:write_ushort(opcode)
    data:write_ushort(csn)
    data:write_ushort(ssn)
    data:write_ubyte(crypt_type)
    data:write_ubyte(crypt_key)
    data:write_bytes(buff, sz)
    return data:pack() -- sock_buff, sock_sz
end
function M.unpack(sock_buff, sock_sz)
    assert(type(sock_buff) == "userdata")
    assert(type(sock_sz) == "number")
    local data      = core.new(sock_buff, sock_sz) 
    --local total     = data:read_ushort() -- skynet抠掉了这2个字节
    local opcode    = data:read_ushort()
    local csn       = data:read_ushort()
    local ssn       = data:read_ushort()
    local crypt_type= data:read_ubyte()
    local crypt_key = data:read_ubyte()
    local sz        = sock_sz - HEADER_SIZE
    local buff      = data:read_bytes(sz)
    return opcode, csn, ssn, crypt_type, crypt_key, buff, sz
end
return M
