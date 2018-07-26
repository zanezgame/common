local skynet        = require "skynet"
local util          = require "util"

local manager, room = ...
assert(manager) -- 房间管理逻辑(xxx.manager)
assert(room)    -- 房间逻辑(xx.room)

local manager = require(manager)

local NORET = "NORET"
local id2agent = {}  -- room id对应的agent
local free_list = {} -- 空闲的agent list

local table_insert = table.insert
local table_remove = table.remove

local function pop_free_agent()
    local agent = free_list[#free_list]
    if agent == 0 then
        return skynet.newservice("room/agent", room)
    end
    free_list[#free_list] = nil
    return agent
end

local CMD = {}
function CMD.start(conf, preload)
    preload = preload or 10     -- 预加载agent数量
    for i = 1, preload do
        local agent = skynet.newservice("room/agent", room)
        table_insert(free_list, agent)
    end
end

skynet.start(function()
    skynet.dispatch("lua", function(_, _, cmd1, ...)
        local ret = NORET
        local f = CMD[cmd1]
        if f then
            util.ret(f(...))
        else
            f = assert(room[cmd1])
            util.ret(f(room, ...))
        end
    end)
end)
