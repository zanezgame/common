local skynet = require "skynet"
local class = require "class"
local util = require "util"
local log = require "log"

local trace = log.trace("webconsole")

local player_skynet_t = class("player_skynet_t")
function player_skynet_t:ctor(player)
    self.player = player
end

local function debug_call(addr, cmd, ...)
    return skynet.call(addr, "debug", cmd, ...)
end

local function debug_send(addr, cmd, ...)
    return skynet.send(addr, "debug", cmd, ...)
end

function player_skynet_t:c2s_all_service()
    local list = {} 
    
    local all = skynet.call(".launcher", "lua", "LIST")
    for addr, desc in pairs(all) do
        table.insert(list, {addr = addr, desc = desc})
    end
    

    for i, v in ipairs(list) do
        local addr = v.addr
        v.mem = debug_call(addr, "MEM")
        if v.mem < 1024 then
            v.mem = math.floor(v.mem).." Kb"
        else
            v.mem = math.floor(v.mem/1024).." Mb"
        end

        local stat = debug_call(addr, "STAT")
        v.task = stat.task
        v.mqlen = stat.mqlen
        v.id = i
        v.address = skynet.address(addr)
    end
    table.sort(list, function(a, b)
        return a.addr < b.addr
    end)
    return {service_list = list}
end

return player_skynet_t
