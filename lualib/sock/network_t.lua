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

function M:init(watchdog, gate, agent, fd)
    self._watchdog = assert(watchdog)
    self._gate = assert(gate)
    self._agent = assert(agent)
    self._fd = assert(fd)
    self._csn = 0
    self._ssn = 0
    self._crypt_key = 0
    self._crypt_type = 0
end

function M:call_watchdog(...)
    return skynet.call(self._watchdog, "lua", ...)
end

function M:call_gate(...)
    return skynet.call(self._gate, "lua", ...)
end

function M:call_agent(...)
    return skynet.call(self._agent, "lua", ...)
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

    local ret = 0 -- 返回整数为错误码，table为返回客户端数据
    local mod = assert(self.player[modulename], modulename)
    local f = assert(mod[simplename], simplename)
    if not util.try(function()
        ret = f(mod, data) or 0
    end) then
        ret = errcode.Traceback    
    end
    if type(ret) == "table" then
        ret.err = ret.err or 0
    else
        ret = {err = ret} 
    end 
    self:send(op+1, ret)
end

function M:reconnect(fd, token)
    skynet.call(self._gate, "lua", "kick", self._fd)
    self._fd = fd
end

function M:get_fd()
    return self._fd
end

function M:get_agent()
    return self._agent
end

return M
