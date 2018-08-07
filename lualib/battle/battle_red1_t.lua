local skynet = require "skynet"
local class = require "class"
local def = require "def"
local battle_t = require "battle.battle_t"

local M = class("battle_red1_t", battle_t)
function M:ctor()
    self.type = def.BattleType.RED1
end

function M:init_by_data(data)
    data = data or {}
    self.type = data.type
end

function M:base_data()
    return {
        type = self.type,
    }
end

return M
