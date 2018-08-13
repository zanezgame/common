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
local acc2player = {}
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

function CMD.init(gate, watchdog, max_count, proto)
    GATE = assert(gate)
    WATCHDOG = assert(watchdog)
    MAX_COUNT = max_count or 100
    protobuf.register_file(proto)
end

-- from watchdog
function CMD.new_player(fd, ip)
    local player = player_t.new()
    player.net:init(WATCHDOG, GATE, skynet.self(), fd, ip)
    fd2player[fd] = player
	skynet.call(GATE, "lua", "forward", fd)
    count = count + 1
    return count >= MAX_COUNT
end

-- from watchdog
function CMD.socket_close(acc, fd)
    local player = assert(acc2player[acc])
    player:offline()
    fd2player[fd] = nil
end

-- from player
function CMD.player_online(acc, fd)
    local player = assert(fd2player[fd])
    acc2player[acc] = player
end

function CMD.free_player(acc)
    print("&&& agent free_player")
    acc2player[acc] = nil
    if count == MAX_COUNT then
        skynet.call(WATCHDOG, "lua", "set_free", skynet.self())
    end
    count = count - 1
end

function CMD.reconnect(fd, acc, token)
    local player = acc2player[acc]
    if not player then
        return
    end
    local old_fd = player.net:get_fd()
    if player.net:reconnect(fd, token) then
        fd2player[old_fd] = nil
        fd2player[fd] = player
        return true
    end
end

skynet.start(function()
	skynet.dispatch("lua", function(_,_, command, ...)
		local f = assert(CMD[command])
		util.ret(f(...))
	end)
end)
