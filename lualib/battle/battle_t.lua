local skynet = require "skynet"
local class = require "class"
local sname = require "sname"
local opcode = require "def.opcode"
local def = require "def"

local M = class("battle_t")
function M:ctor(player)
    self.player = player
    self.mode = def.BattleMode.NORMAL
    self.room_id = nil
    self.room_agent = nil
    self.enemy = nil
end

function M:call_room(cmd, ...)
    return skynet.call(self.room_agent, "lua", self.room_id, cmd, self.player.uid, ...)
end

function M:send(op, data)
    self.player.net:send(op, data) 
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

function M:create_room(enemyid)
    self.enemyid = enemyid
    local room_id, agent = skynet.call(sname.ROOMCENTER, "lua", "create_room", self.player.uid, enemyid)
    self.room_id = room_id
    self.room_agent = agent
    self:call_room("join", skynet.self(), {
        uid = self.player.uid,
        gender = self.player.user.gender,
        avatar = self.player.user.avatar,
        name = self.player.user.name,
    })
end

function M:on_join(uid, enemy)
    self.enemy = enemy
    self:send(opcode.battle.s2c_player_join, {
        player = {
            uid = enemy.uid,
            gender = enemy.gender,
            avatar = enemy.avatar,
            name = enemy.name,
        }
    })
end

function M:ready()
    self:call_room("ready")
end

function M:sync(score)
    self:call_room("sync", score)
end

function M:giveup()
    self:call_room("giveup")
end

return M
