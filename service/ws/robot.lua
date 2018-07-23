local skynet = require "skynet"
local json = require "cjson"
local ws_client = require "ws.ws_client"

local player = ...
local player = require "player"

local NORET = "NORET"
local socks = {}

local CMD = {}
function CMD.new(url)
    local ws = ws_client.new()
    local player = player.new()
    ws:connect(string.format(url))
    socks[ws] = player
    player:on_open(ws)
end

function CMD.recv()
    for ws, player in pairs(socks) do
        local ret = ws:recv_frame()
        if ret then
            print("recv", ret)
            player:on_message(ret)
        end
    end
    skynet.timeout(100, function()
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

