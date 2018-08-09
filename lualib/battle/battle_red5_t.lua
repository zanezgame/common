local skynet = require "skynet"
local class = require "class"
local def = require "def"
local battle_t = require "battle.battle_t"

local M = class("battle_red5_t", battle_t)
function M:ctor()
    self.mode = def.BattleMode.RED5
end

function M:init_by_data(data)
    data = data or {}
    self.mode = data.mode
end

function M:base_data()
    return {
        mode = self.mode,
    }
end

return M
