local skynet = require "skynet"
local class = require "class"
local network_t = require "ws.network_t"
local log = require "log"

local trace = log.trace("webconsole")

local player_t = class("player_t")
function player_t:ctor()
    self.net = network_t.new(self)
end

function player_t:c2s_login()
    trace("webconsole login") 
end

return player_t
