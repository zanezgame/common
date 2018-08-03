local skynet    = require "skynet"
local socket    = require "skynet.socket"
local packet    = require "sock.packet"
local util      = require "util"
local opcode    = require "def.opcode"
local protobuf  = require "protobuf"

local player_path, MAX_COUNT = ...
local player_t = require(player_path)

local WATCHDOG
local GATE
local MAX_COUNT

local CMD = {}
local fd2player = {}
local uid2player = {}
local count = 0

skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
	unpack = function (buff, sz)
		return packet.unpack(buff, sz)
	end,
	dispatch = function (fd, _, ...)
		skynet.ignoreret()	-- session is fd, don't call skynet.ret

        local player = assert(fd2player[fd], "player not exist, fd:"..fd)
        player.net:recv(...)
	end
}

function CMD.new_player(fd)
    local player = player_t.new()
    player.net:init(GATE, fd)
    fd2player[fd] = player
	skynet.call(GATE, "lua", "forward", fd)
    count = count + 1
    return count >= MAX_COUNT
end

function CMD.online(uid, fd)
    local player = assert(fd2player[fd])
    uid2player[uid] = player
end

function CMD.free_player(uid)
    uid2player[uid] = nil
    if count == MAX_COUNT then
        skynet.call(WATCHDOG, "lua", "set_free", skynet.self())
    end
    count = count - 1
end

function CMD.socket_close(fd)
    local player = assert(fd2player[fd])
    player:offline()
    fd2player[fd] = nil
end

function CMD.init(gate, watchdog, max_count, proto)
    GATE = assert(gate)
    WATCHDOG = assert(watchdog)
    MAX_COUNT = max_count or 100
    protobuf.register_file(proto)
end

skynet.start(function()
	skynet.dispatch("lua", function(_,_, command, ...)
		local f = assert(CMD[command])
		util.ret(f(...))
	end)
end)
