local skynet        = require "skynet"
local socket        = require "skynet.socket"
local json          = require "cjson"
local util          = require "util"
local ws_server     = require "ws.server"
local opcode        = require "def.opcode"
local errcode       = require "def.errcode"

local player_path   = ...
local player_t      = require(player_path)
local player        = player_t.new()

local ws
local protobuf  -- 需要在节点启动时初始化 util.init_proto_env()
local send_type -- text/binary
local CMD = {}

local handler = {}
function handler.open()
end

function handler.text(t)
    send_type = "text"

    skynet.error("recv", t)
    local data = json.decode(t)
    local recv_id = data.id
    if recv_id == "HearBeatPing" then
        -- todo change name
        return message
    end
    local resp_id = "S2c"..string.match(recv_id, "C2s(.+)")
    assert(player[recv_id], "net handler nil")
    if player[recv_id] then
        local msg = player[recv_id](player, data.msg) or {}
        ws:send_text(json.encode({
            id = resp_id,
            msg = msg,
        }))
    end
end

function handler.binary(sock_buff)
    send_type = "binary"

    local op, buff = string.unpack(">Hs2", sock_buff)
    local opname = opcode.toname(op)
    local modulename = opcode.tomodule(op)
    local simplename = opcode.tosimplename(op)
    if opcode.has_session(op) then
        print(string.format("recv package, 0x%x %s", op, opname))
    end

    local data = protobuf.decode(opname, buff, sz)
    util.printdump(data)

    if not util.try(function()
        assert(player, "player nil")
        assert(player[modulename], string.format("module nil [%s.%s]", modulename, simplename))
        assert(player[modulename][simplename], string.format("handle nil [%s.%s]", modulename, simplename))
        ret = player[modulename][simplename](player[modulename], data) or 0
    end) then
        ret = errcode.Traceback
    end 

    assert(ret, string.format("no respone, opname %s", opname))
    if type(ret) == "table" then
        ret.err = ret.err or 0
    else
        ret = {err = ret} 
    end                                                                                                                                                                                                                              
    player:send(op+1, ret)
end

function handler.close()

end

local function send_text(id, msg) -- 兼容text
    ws:send_text(json.encode({
        id  = id,
        msg = msg,
    }))
end

local function send_binary(op, tbl)
    local data = protobuf.encode(opcode.toname(op), tbl)
    print("send", #data)
    ws:send_binary(string.pack(">Hs2", op, data))
end

function player:send(...)
    if send_type == "binary" then
        send_binary(...)
    elseif send_type == "text" then
        send_text(...)
    else
        skynet.error("send_type error", send_type)
    end
end

function CMD.start(watchdog, fd)
    socket.start(fd)
    ws = ws_server.new(fd, handler)
    player:init(watchdog, ws)
end

skynet.start(function()
    skynet.dispatch("lua", function(_, _, cmd1, cmd2, ...)
        local f = CMD[cmd1]
        if f then
            util.ret(f(cmd2, ...))
        elseif player[cmd1] then
            local module = player[cmd1]
            if type(module) == "function" then
                util.ret(module(player, cmd2, ...))
            else
                util.ret(module[cmd2](module, ...))
            end
        end
    end)
    protobuf = util.get_protobuf()
    
end)

