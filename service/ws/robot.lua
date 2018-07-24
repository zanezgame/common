local skynet = require "skynet"
local json = require "cjson"
local ws_client = require "ws.client"

local player_t = ...
local player_t = require "player_t"

local NORET = "NORET"
local players = {}

local CMD = {}
function CMD.new(url)
    local ws = ws_client.new()
    ws:connect(string.format(url))
    local player = player_t.new(ws)
    players[ws] = player
    player:on_open()
end

function CMD.recv()
    for ws, player in pairs(players) do
        while true do
            local ret = ws:recv_frame()
            if ret then
                print("recv", ret)
                player:on_message(ret)
            else
                break
            end
        end
    end
    skynet.timeout(10, function()
        CMD.recv()
    end)
end

function CMD.close()
    -- todo
end

skynet.start(function()		
    skynet.dispatch("lua", function(_, _, cmd1, cmd2, ...)
        local ret = NORET
        local f = CMD[cmd1]
        assert(f)
        ret = f(cmd2, ...)
        if ret ~= NORET then
            skynet.ret(skynet.pack(ret))
        end
    end)

    CMD.recv()
end)

