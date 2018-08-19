local skynet = require "skynet"
local class = require "class"
local network_t = require "ws.network_t"
local player_skynet_t = require "webconsole.player_skynet_t"
local player_login_t = require "webconsole.player_login_t"

local log = require "log"
local trace = log.trace("webconsole")

local player_t = class("player_t")
function player_t:ctor()
    self.net = network_t.new(self)
    self.login = player_login_t.new(self)
    self.skynet = player_skynet_t.new(self)
end
return player_t
