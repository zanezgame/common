local skynet = require "skynet"
local class = require "class"
local sname = require "sname"
local opcode = require "def.opcode"
local def = require "def"

local M = class("player_battle_t")
function M:ctor(player)
    self.player = assert(player, "battle need player")
    for _, t in pairs(def.BattleMode) do
       local battle_class = require(def.BattleClass[t])
       self[t] = battle_class.new(player)
    end
    self.battle = nil
end

function M:init_by_data(data)
    data = data or {}
end

function M:base_data()
    return {
    }
end

function M:room_command(cmd, ...)
    assert(self.battle)
    assert(self.battle[cmd], cmd)
    return self.battle[cmd](self.battle, ...)
end

function M:match(mode)
    skynet.call(sname.MATCHCENTER, "lua", "match", mode, 
        self.player.uid, 1, skynet.self()) 
end

function M:matched(mode, targetid)
    self.battle = assert(self[mode])
    self.battle:create_room(targetid)
end

function M:create_room()
    
end

function M:ready()
    if not self.battle then
        return errocode.NotInBattle
    end
    self.battle:ready()
end

function M:sync(score)
    if not self.battle then
        return errocode.NotInBattle
    end
    self.battle:sync(score)
end

function M:giveup()
    if not self.battle then
        return errocode.NotInBattle
    end
    self.battle:giveup()
end

-- network
function M:c2s_match(data)
    return self:match(data.mode) 
end

function M:c2s_create_room(data)

end

function M:c2s_ready(data)
    return self:ready()
end

function M:c2s_sync(data)
    return self:sync(data.score)
end

function M:c2s_giveup(data)

end

return M
