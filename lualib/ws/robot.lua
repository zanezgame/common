local skynet    = require "skynet"
local packet    = require "packet"
local protobuf  = require "protobuf"
local opcode    = require "def.opcode"
local util      = require "util"
local json      = require "cjson"
local ws_client = require "ws.client"

local M = {}
local mt = {__index = M}
function M.new(...)
    local t = {}
    M.ctor(t, ...)
    return setmetatable(t, mt)
end

function M:ctor(url, send_type, player)
    self.url = url
    self.send_type = send_type or "text"
    self.ws = ws_client:new()
    self.player = player
end

function M:start()
    assert(self.ws)

    skynet.fork(function()
        while true do
            local data, type, err = ws:recv_frame()
            if t == "text" then
                self:recv_text(data) 
            elseif t == "binary" then
                self:recv_binary(data)
            end
        end
    end)
end

function M:send(...)
    if self.send_type == "text" then
        self:send_text(...)
    elseif self.send_type == "binary" then
        self:send_binary(...)
    end
end

function M:recv_binary(sock_buff)
    local data      = packetc.new(sock_buff) 
    local total     = data:read_ushort()
    local op        = data:read_ushort()
    local csn       = data:read_ushort()
    local ssn       = data:read_ushort()
    local crypt_type= data:read_ubyte()
    local crypt_key = data:read_ubyte()
    local sz        = #sock_buff - 10 - 2
    local buff      = data:read_bytes(sz)
    --local op, csn, ssn, crypt_type, crypt_key, buff, sz = packet.unpack(sock_buff)
    print(op, csn ,ssn, crypt_type, crypt_key, buff, sz)
    self.ssn = ssn

    local opname = opcode.toname(op)
    local modulename = opcode.tomodule(op)
    local simplename = opcode.tosimplename(op)
    if opcode.has_session(op) then
        print(string.format("recv package, 0x%x %s, csn:%d", op, opname, csn))
    end

    local data = protobuf.decode(opname, buff, sz)
    print(data)
    util.printdump(data)
end

function M:send_binary(op, tbl)
    self.csn = self.csn + 1
    
    local data, len
    protobuf.encode(opcode.toname(op), tbl, function(buffer, bufferlen)
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
