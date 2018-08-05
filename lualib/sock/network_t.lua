local skynet    = require "skynet"
local class     = require "class"
local socket    = require "skynet.socket"
local packet    = require "sock.packet"
local util      = require "util"
local opcode    = require "def.opcode"
local errcode   = require "def.errcode"
local protobuf  = require "protobuf"

local M = class("network_t")
function M:ctor(player)
    self.player = assert(player, "network need player")
end

function M:init(gate, fd)
    self._gate = assert(gate)
    self._fd = assert(fd)
    self._csn = 0
    self._ssn = 0
    self._crypt_key = 0
    self._crypt_type = 0
end

function M:send(op, tbl) 
    self._ssn = self._ssn + 1
    local data, len
    protobuf.encode(opcode.toname(op), tbl, function(buffer, bufferlen)
        data, len = packet.pack(op, self._csn, self._ssn, 
            self._crypt_type, self._crypt_key, buffer, bufferlen)
    end)
	socket.write(self._fd, data, len + 2)
end

function M:recv(op, csn, ssn, crypt_type, crypt_key, buff, sz)
    local opname = opcode.toname(op)
    local modulename = opcode.tomodule(op)
    local simplename = opcode.tosimplename(op)
    if opcode.has_session(op) then
        skynet.error("recv package, 0x%x %s, csn:%d", op, opname, csn)
    end

    local data = protobuf.decode(opname, buff, sz)
    assert(type(data) == "table", data)
    util.printdump(data)

    self:send(op+1, {err = 88})
end

return M
