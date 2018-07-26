local skynet = require "skynet"
local socket = require "skynet.socket"
local sproto = require "sproto"
local util   = require "util"

local player = ...
player = require(player)

local FD
local WATCHDOG
local GATE

local CMD = {}
local client_fd

local function send_package(pack)
	local package = string.pack(">s2", pack)
	socket.write(client_fd, package)
end

skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
	unpack = function (msg, sz)
		return host:dispatch(msg, sz)
	end,
	dispatch = function (fd, _, type, ...)
		assert(fd == FD)	-- You can use fd to reply message
		skynet.ignoreret()	-- session is fd, don't call skynet.ret
		skynet.trace()
	end
}

function CMD.start(conf)
	FD = conf.fd
	GATE = conf.gate
    WATCHDOG = conf.WATCHDOG

	skynet.call(GATE, "lua", "forward", fd)
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
