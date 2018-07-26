local skynet    = require "skynet"
local socket    = require "skynet.socket"
local json      = require "cjson"
local util      = require "util"
local ws_server = require "ws.server"

local player = ...
local player = require(player)

local ws
local CMD = {}

local handler = {}
function handler.open()
    print("open")
end
function handler.text(t)
    --print("recv", data)
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
        return json.encode({
            id = recv_id,
            msg = msg,
        })
    end
end
function handler.close()

end

function CMD.start(watchdog, fd)
    player:init(watchdog, fd)

    socket.start(fd)
    ws = ws_server.new(fd, handler)
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
end)

