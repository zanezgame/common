local skynet    = require "skynet"
local websocket = require "ws.socket"
local json      = require "cjson"
local util      = require "util"

local sock_id, player, ws_gate = ...
sock_id = tonumber(sock_id)
ws_gate = tonumber(ws_gate)
local player = require(player)

local NORET = "NORET"

local CMD = {}
function CMD.on_open()
    print("ws on_open")
end

function CMD.on_message(message)
    local data = json.decode(message)
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

function CMD.on_close()
    print("ws on_close")
end

skynet.start(function()
    skynet.dispatch("lua", function(_, _, cmd1, cmd2, ...)
        local ret = NORET
        local f = CMD[cmd1]
        if f then
            ret = f(cmd2, ...)
        elseif player[cmd1] then
            local module = player[cmd1]
            if type(module) == "function" then
                ret = module(player, cmd2, ...)
            else
                ret = module[cmd2](module, ...)
            end
        end
        if ret ~= NORET then
            skynet.ret(skynet.pack(ret))
        end
    end)
    player:init(ws_gate, sock_id)
end)

