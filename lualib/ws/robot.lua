local skynet    = require "skynet"
local packet    = require "ws.packet"
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

function M:ctor(url, player, send_type)
    self.url = url
    self.send_type = send_type or "text"
    self.ws = ws_client:new()
    self.player = player
end

function M:start()
    assert(self.ws)
    self.ws:connect(self.url)

    skynet.fork(function()
        while true do
            local data, type, err = self.ws:recv_frame()
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

function M:recv_text(text)

end

function M:send_text(id, msg)
    self.ws:send_text(json.encode({
        id = resp_id,
        msg = msg,
    }))
end

function M:recv_binary(sock_buff)
    local op, buff = string.unpack(">Hs2", sock_buff)
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
    local data = protobuf.encode(opcode.toname(op), tbl)
    --print("send", data, #data)
    self.ws:send_binary(string.pack(">Hs2", op, data))
end

function M:call()

end

function M:test(func)
    
end

return M
