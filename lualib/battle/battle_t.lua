local skynet = require "skynet"
local class = require "class"
local sname = require "sname"
local def = require "def"

local M = class("battle_t")
function M:ctor(player)
    self.player = player
    self.mode = def.BattleMode.NORMAL
    self.room_id = nil
    self.room_agent = nil
end

function M:call_room(...)
    return skynet.call(self.room_agent, "lua", self.room_id, ...)
end

function M:init_by_data(data)
    data = data or {}
    self.mode = data.mode
    self.enemyid = data.enemyid
end

function M:base_data()
    return {
        mode = self.mode,
        enemyid = self.enemyid
    }
end

function M:is_robot()
    return self.enemyid == 0
end

function M:start(enemyid)
    self.enemyid = enemyid
    local room_id, agent = skynet.call(sname.ROOMCENTER, "lua", "create_room", self.player.uid, enemyid)
    self.room_id = room_id
    self.room_agent = agent
    self:call_room("join", self.player.uid, skynet.self())
end


return M
