local skynet    = require "skynet"
local socket    = require "skynet.socket"
local json      = require "cjson"
local util      = require "util"
local ws_server = require "ws.server"
local opcode    = require "def.opcode"

local player    = ...
local player    = require(player)

local ws
local protobuf -- 需要在节点启动时初始化 util.init_proto_env()
local CMD = {}

local handler = {}
function handler.open()
end

function handler.text(t)
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
    local op, buff = string.unpack(">Hs2", sock_buff)
    local opname = opcode.toname(op)
    local modulename = opcode.tomodule(op)
    local simplename = opcode.tosimplename(op)
    if opcode.has_session(op) then
        print(string.format("recv package, 0x%x %s", op, opname))
    end

    local data = protobuf.decode(opname, buff, sz)
    util.printdump(data)
end

function handler.close()

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

