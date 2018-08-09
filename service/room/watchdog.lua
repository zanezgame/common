local skynet = require "skynet"
local util = require "util"
local db = require "db.redis_helper"

local agents = {}
local id2agent = {} -- room_id -> agent
local balance = 1

local CMD = {}
function CMD.init(room_path, preload)
    preload = preload or 10
    for i = 1, preload do
        agents[i] = skynet.newservice("room/agent", room_path)
    end
end

-- 以创建房间的人的uid作为room_id
function CMD.create_room(my_id, enemy_id)
    local agent = id2agent[enemy_id]
    if enemy_id and id2agent[enemy_id] then
        return enemy_id, id2agent[enemy_id]
    end
    assert(not id2agent[my_id], "room created")

    balance = balance + 1
    if balance > #agents then
        balance = 1
    end
    local agent = agents[balance]
    return my_id, agent
end

function CMD.destroy_room(room_id)
    id2agent[room_id] = nil
end


skynet.start(function()
    skynet.dispatch("lua", function(_,_, cmd, ...)
        local f = assert(CMD[cmd], cmd)
        util.ret(f(...))
    end)
end)

