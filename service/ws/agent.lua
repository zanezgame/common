local skynet        = require "skynet"
local socket        = require "skynet.socket"
local json          = require "cjson"
local util          = require "util"
local opcode        = require "def.opcode"
local errcode       = require "def.errcode"
local protobuf      = require "protobuf"

local player_path   = ...
local player_t      = require(player_path)

local WATCHDOG
local MAX_COUNT

local send_type -- text/binary
local CMD = {}
local fd2player = {}
local uid2player = {}
local count = 0


function CMD.new_player(fd)
    socket.start(fd)
    local player = player_t.new()
    player.net:init(WATCHDOG, skynet.self(), fd)
    fd2player[fd] = player
    count = count + 1
    return count >= MAX_COUNT
end

function CMD.init(watchdog, max_count, proto)
    WATCHDOG = assert(watchdog)
    MAX_COUNT = max_count or 100
    if proto then
        protobuf.register_file(proto)
    end
end

-- from player
function CMD.player_online(uid, fd)
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

-- from watchdog
function CMD.socket_close(fd)
    local player = assert(fd2player[fd])
    player:offline()
    fd2player[fd] = nil
end


skynet.start(function()
    skynet.dispatch("lua", function(_, _, arg1, arg2, arg3, ...)
        local f = CMD[arg1]
        if f then
            util.ret(f(arg2, arg3, ...))
        else
            local player = assert(uid2player[arg1], arg1)
            local module = assert(player[arg2], arg2)
            if type(module) == "function" then
                util.ret(module(player, arg3, ...))
            else
                util.ret(module[arg3](module, ...))
            end
        end
    end)
end)

