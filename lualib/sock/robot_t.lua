local skynet    = require "skynet"
local socket    = require "skynet.socket"
local coroutine = require "skynet.coroutine"
local http      = require "web.http_helper"
local packet    = require "sock.packet"
local packetc   = require "packet.core"
local protobuf  = require "protobuf"
local opcode    = require "def.opcode"
local util      = require "util"
local json      = require "cjson"
local class     = require "class"

local fd

local M = class("robot_t")
function M:ctor(proj_name)
    self._proj_name = proj_name
    self._host = nil
    self._port = nil
    self._fd = nil
    self._csn = 0 -- client session
    self._ssn = 0 -- server session
    self._crypt_type = 0
    self._crypt_key = 0

    self._call_requests = {} -- op -> co
    self._waiting = {} -- co -> time
end

function M:login(acc)
    --local ret, resp = http.get("http://www.kaizhan8.com:8888/login/req_login", {
    local ret, resp = http.get("http://huangjx.top/login/req_login", {
        proj_name = self._proj_name 
    })
    if resp == "error" then
        return
    end
    --print(ret, resp)
    local data = json.decode(resp)
    self._host = data.host
    self._port = data.port
end

function M:start(host, port)
    self._host = assert(host)
    self._port = assert(port)
    self._fd = socket.open(self._host, self._port)
    assert(self._fd)

    skynet.fork(function()
        while true do
            local buff = socket.read(self._fd)
            if not buff then
                self:offline()
                return
            end
            self:_recv(buff)
        end
    end)
 
    -- ping
    skynet.fork(function()
        while true do
            self:ping()
            skynet.sleep(100*30)
        end
    end)

    -- tick
    self.tick = 0
    skynet.fork(function()
        while true do
            self.tick = self.tick + 1
            skynet.sleep(1)
            for co, time in pairs(self._waiting) do
                if time <= 0 then
                    self:_suspended(co)
                else
                    self._waiting[co] = time - 1
                end
            end
        end
    end)
end

function M:test(func)
    local co = coroutine.create(function()
        util.try(func)  
    end)
    self:_suspended(co)
end

function M:call(op, data)
    self:send(op, data)
    return coroutine.yield(op)
end

function M:wait(time)
    return coroutine.yield(nil, time)
end

function M:send(op, tbl)
    self._csn = self._csn + 1
    
    local data, len
    protobuf.encode(opcode.toname(op), tbl, function(buffer, bufferlen)
        data, len = packet.pack(op, self._csn, self._ssn, 
            self._crypt_type, self._crypt_key, buffer, bufferlen)
    end)

    --print(string.format("send %s, csn:%d", opcode.toname(op), self._csn))
    socket.write(self._fd, data, len+2)
end

function M:ping()
    -- overwrite
end

function M:offline()
    -- overwrite
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
    --print(string.format("recv %s, csn:%d ssn:%d", opname, csn, ssn))

    local data = protobuf.decode(opname, buff, sz)

    local co = self._call_requests[op - 1]
    self._call_requests[op - 1] = nil
    if co and coroutine.status(co) == "suspended" then
        self:_suspended(co, op, data)
    end
end

function M:_suspended(co, op, ...)
    assert(op == nil or op >= 0)
    local status, op, wait = coroutine.resume(co, ...)
    if coroutine.status(co) == "suspended" then                                                                                                                                                                                  
        if op then
            self._call_requests[op] = co
        end
        if wait then
            self._waiting[co] = wait
        end
    end
end

return M
