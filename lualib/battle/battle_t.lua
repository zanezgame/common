local skynet = require "skynet"
local class = require "class"
local def = require "def"

local M = class("battle_t")
function M:ctor()
    self.type = def.BattleType.NORMAL
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
