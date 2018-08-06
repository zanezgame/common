local skynet = require "skynet"
local util = require "util"
local db = require "db.redis_helper"

local room_path, preload = ...
local agents = {}
local balance = 1

local CMD = {}
function CMD.create_room()
    balance = balance + 1
    if balance > #agents then
        balance = 1
    end
    local agent = agents[balance]
    local room_id = db.auto_id()
    return room_id, agent
end

skynet.start(function()
    preload = preload or 10
    for i = 1, preload do
        agents[i] = skynet.newservice("room/agent", room_path)
    end
    skynet.dispatch("lua", function(_,_, cmd, ...)
        local f = assert(CMD[cmd], cmd)
        util.ret(f(...))
    end)
end)

