local skynet = require "skynet"
local socket = require "skynet.socket"
local packet = require "packet"
local util   = require "util"

local player = ...
player = require(player)

local FD
local WATCHDOG
local GATE

local CMD = {}

local function send_package(pack)
	local package = string.pack(">s2", pack)
	socket.write(FD, package)
end

skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
	unpack = function (buff, sz)
        print("recv buff", buff, sz)
		return packet.unpack(buff, sz)
	end,
	dispatch = function (fd, _, ...)
        print("recv", ...)
		assert(fd == FD)	-- You can use fd to reply message
		skynet.ignoreret()	-- session is fd, don't call skynet.ret
	end
}

function CMD.start(conf)
	FD = conf.fd
	GATE = conf.gate
    WATCHDOG = conf.WATCHDOG
    
	skynet.call(GATE, "lua", "forward", FD)
    print("agent start &&&&&&&&&&&", FD)
    send_package("hello")
end

function CMD.disconnect()
	-- todo: do something before exit
	skynet.exit()
end

skynet.start(function()
	skynet.dispatch("lua", function(_,_, command, ...)
		local f = CMD[command]
		util.ret(f(...))
	end)
end)
