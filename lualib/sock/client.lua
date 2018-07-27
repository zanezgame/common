-- 一个虚拟机只能有一个
local skynet    = require "skynet"
local socket    = require "skynet.socket"
local packet    = require "packet"
local protobuf  = require "protobuf"
local opcode    = require "def.opcode"
local util      = require "util"

local fd

local M = {}
local mt = {__index = M}
function M.new(...)
    local t = {}
    M.ctor(t, ...)
    return setmetatable(t, mt)
end

function M:ctor(host, port)
    self.host = host
    self.port = port
    self.fd = nil
    self.csn = 0 -- client session
    self.ssn = 0 -- server session
    self.crypt_type = 0
    self.crypt_key = 0
end

function M:start()
    self.fd = socket.open(self.host, self.port)
    assert(self.fd)

    skynet.fork(function()
        while true do
            local buff = socket.read(self.fd, sz)
            self:recv_package(buff)
            skynet.sleep(100)
        end
    end)
end

function M:recv_package(sock_buff)
    print("recv &&&&", sock_buff)
    local op, csn, ssn, crypt_type, crypt_key, buff, sz = packet.unpackstring(sock_buff)
    print(op, csn ,ssn, crypt_type, crypt_key, buff, sz)
    self.ssn = ssn

    local opname = opcode.toname(op)
    local modulename = opcode.tomodule(op)
    local simplename = opcode.tosimplename(op)
    if opcode.has_session(op) then
        print(string.format("recv package, 0x%x %s, csn:%d", op, opname, csn))
    end

    local data = protobuf.decode(opname, buff, sz)
    util.printdump(data)
end

function M:send(op, tbl)
    self.csn = self.csn + 1
    
    local data, len
    protobuf.encode(opcode.toname(op), tbl, function(buffer, bufferlen)
        print("protobuf", bufferlen)
        data, len = packet.pack(op, self.csn, self.ssn, 
            self.crypt_type, self.crypt_key, buffer, bufferlen)
    end)

    print("send", data, len)
    socket.write(self.fd, data, len+2)
    --socket.write(self.fd, string.pack(">s2", data) )
end

function M:call()

end

function M:test(func)
    
end

return M
