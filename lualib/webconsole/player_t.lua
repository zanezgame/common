local skynet = require "skynet"
local class = require "class"
local network_t = require "ws.network_t"
local player_skynet_t = require "webconsole.player_skynet_t"

local log = require "log"
local trace = log.trace("webconsole")

local player_t = class("player_t")
local player_login_t = class("player_login_t")
function player_t:ctor()
    self.net = network_t.new(self)
    self.login = player_login_t.new(self)
    self.skynet = player_skynet_t.new(self)
end


function player_login_t:ctor(player)
    self.player = player
end

function player_login_t:c2s_login()
    trace("webconsole login") 
end

return player_t
