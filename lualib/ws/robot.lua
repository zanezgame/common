local skynet    = require "skynet"
local coroutine = require "skynet.coroutine"
local packet    = require "ws.packet"
local protobuf  = require "protobuf"
local opcode    = require "def.opcode"
local errcode   = require "def.errcode"
local util      = require "util"
local json      = require "cjson"
local ws_client = require "ws.client"

local M = {}
local mt = {__index = M}
function M.new(...)
    local t = {}
    M._ctor(t, ...)
    return setmetatable(t, mt)
end

function M:_ctor(url, send_type)
    self._url = url
    self._send_type = send_type or "text"
    self._ws = ws_client:new()
    self._call_requests = {} -- op -> co
end

function M:start()
    assert(self._ws)
    self._ws:connect(self._url)

    -- recv
    skynet.fork(function()
        while true do
            local data, type, err = self._ws:recv_frame()
            if type == "text" then
                self:_recv_text(data) 
            elseif type == "binary" then
                self:_recv_binary(data)
            end
            --skynet.sleep(10)
        end
    end)
    
    -- ping
    if self.ping then
        skynet.fork(function()
            while true do
                self:ping()
                skynet.sleep(100*10)
            end
        end)
    end
end

function M:test(func)
    local co = coroutine.create(func)
    self:_suspended(co)
end

function M:call(op, data)
    self:send(op, data)
    return coroutine.yield(op)
end

function M:send(...)
    skynet.sleep(10)
    if self._send_type == "text" then
        self:_send_text(...)
    elseif self._send_type == "binary" then
        self:_send_binary(...)
    end
end

function M:_suspended(co, op, ...)
    assert(op == nil or type(op) == "string" or op >= 0) -- 暂时兼容text
    local status, op = coroutine.resume(co, ...)
    if coroutine.status(co) == "suspended" then                                                                                                                                                                                  
        self._call_requests[op] = co
    end
end

function M:_recv_text(text)
    local data = json.decode(text)
    --util.printdump(data)
    local recv_id = data.id
    if recv_id == "HearBeatPing" then return end
    local req_id = "C2s"..string.match(recv_id, "S2c(.+)")
    if self[recv_id] then
        self[recv_id](self, data.msg)     
    end
    
    local co = self._call_requests[req_id]
    self._call_requests[req_id] = nil
    if co and coroutine.status(co) == "suspended" then
        self:_suspended(co, recv_id,  data.msg)
    end
    return
end

function M:_send_text(id, msg)
    self._ws:send_text(json.encode({
        id = id,
        msg = msg,
    }))
end

function M:_dispatch(op, data)
    local modulename = opcode.tomodule(op)
    local simplename = opcode.tosimplename(op)
    local funcname = modulename .. "_" .. simplename
    if self[funcname] then
        self[funcname](self, data) 
    end
    
    local co = self._call_requests[op - 1]
    self._call_requests[op - 1] = nil
    if co and coroutine.status(co) == "suspended" then
        self:_suspended(co, op, data)
    end
end

function M:_recv_binary(sock_buff)
    print("recv_binary", #sock_buff)
    local op, buff = string.unpack(">Hs2", sock_buff)
    local opname = opcode.toname(op)
    
    local data = protobuf.decode(opname, buff, sz)
    util.printdump(data)
    self:_dispatch(op, data)
end

function M:_send_binary(op, tbl)
    local data = protobuf.encode(opcode.toname(op), tbl)
    --print("send", data, #data)
    self._ws:send_binary(string.pack(">Hs2", op, data))
end

return M
