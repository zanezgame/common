local skynet    = require "skynet"
local socket    = require "skynet.socket"
local coroutine = require "skynet.coroutine"
local packet    = require "sock.packet"
local packetc   = require "packet.core"
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
    self._host = host
    self._port = port
    self._fd = nil
    self._csn = 0 -- client session
    self._ssn = 0 -- server session
    self._crypt_type = 0
    self._crypt_key = 0

    self._call_requests = {} -- op -> co
end

function M:start()
    self._fd = socket.open(self._host, self._port)
    assert(self._fd)

    skynet.fork(function()
        while true do
            local buff = socket.read(self._fd)
            self:_recv(buff)
        end
    end)
end

function M:test(func)
    local co = coroutine.create(func)
    self:_suspended(co)
end

function M:call(op, data)
    self:send(op, data)
    return coroutine.yield(op)
end

function M:send(op, tbl)
    self._csn = self._csn + 1
    
    local data, len
    protobuf.encode(opcode.toname(op), tbl, function(buffer, bufferlen)
        data, len = packet.pack(op, self._csn, self._ssn, 
            self._crypt_type, self._crypt_key, buffer, bufferlen)
    end)

    print(string.format("send %s, csn:%d", opcode.toname(op), self._csn))
    socket.write(self._fd, data, len+2)
end

function M:_recv(sock_buff)
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
    self._ssn = ssn

    local opname = opcode.toname(op)
    local modulename = opcode.tomodule(op)
    local simplename = opcode.tosimplename(op)
    local funcname = modulename .. "_" .. simplename
    if self[funcname] then
        self[funcname](self, data) 
    end
    print(string.format("recv %s, csn:%d ssn:%d", opname, csn, ssn))

    local data = protobuf.decode(opname, buff, sz)

    local co = self._call_requests[op - 1]
    self._call_requests[op - 1] = nil
    if co and coroutine.status(co) == "suspended" then
        self:_suspended(co, op, data)
    end
end

function M:_suspended(co, op, ...)
    assert(op == nil or op >= 0)
    local status, op = coroutine.resume(co, ...)
    if coroutine.status(co) == "suspended" then                                                                                                                                                                                  
        self._call_requests[op] = co
    end
end

return M
