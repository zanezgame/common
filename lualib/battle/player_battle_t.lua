local skynet = require "skynet"
local class = require "class"
local sname = require "sname"
local def = require "def"

local M = class("player_battle_t")
function M:ctor(player)
    self.player = assert(player, "battle need player")
    for _, t in pairs(def.BattleMode) do
       local battle_class = require(def.BattleClass[t])
       self[t] = battle_class.new()
    end
end

function M:init_by_data(data)
    data = data or {}
end

function M:base_data()
    return {
    }
end

function M:match(mode)
    print("&&&& match")
    skynet.call(sname.MATCHCENTER, "lua", "match", mode, 
        self.player.uid, 1, skynet.self()) 
end

function M:matched(mode, targetid)
    print("&&&& matched", mode, targetid)
end

function M:create_room()

end

function M:ready()

end

function M:giveup()

end

-- network
function M:c2s_match(data)
    return self:match(data.mode) 
end

function M:c2s_create_room(data)

end

function M:c2s_ready(data)

end

function M:c2s_sync(data)

end

function M:c2s_giveup(data)

end

return M
