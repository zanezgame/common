local skynet = require "skynet.manager"
local cluster = require "skynet.cluster"
local socket = require "skynet.socket"
local packet = require "packet"
local opcode = require "define.opcode"
local errcode = require "define.errcode"
local util = require "common.util"
local prop = require "prop"
local config = require "config"
local db = require "common.db"

local trace = util.trace("agent")

local loginserver
local gameserver
local warserver

local client
local gate
local CMD = {}
local NORET = "NORET"
local session = 0
local protobuf
local player

skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
	unpack = function (buffer, len)
        return packet.unpack(buffer, len)
    end,
    dispatch = function (_, _, op, session, buffer, len)
        local opname = opcode.toname(op)
        local modulename = opcode.tomodule(op)
        local simplename = opcode.tosimplename(op)
        if opcode.has_session(op) then
            trace("recv package, 0x%x %s, session:%d", op, opname, session)
        end

        local data = protobuf.decode(opname, buffer, len)
       
        local ret = 0 -- 返回整数为错误码，table为返回客户端数据
        if op >= 0xa000 and op <= 0xafff then
            if not skynet.try(function()
                ret = skynet.call(loginserver, "lua", "recv_package", skynet.self(), modulename,
                    simplename, data)
            end) then
                ret = errcode.Traceback
            end
        end

        if op >= 0x1000 and op <= 0x4fff and player then
            if not skynet.try(function()
                assert(player, "player nil")
                assert(player[modulename], string.format("module nil [%s.%s]", modulename, simplename))
                assert(player[modulename][simplename], string.format("handle nil [%s.%s]", modulename, simplename))
                ret = player[modulename][simplename](player[modulename], data) or 0
            end) then
                ret = errcode.Traceback
            end
        end

        if op >= 0x5000 and op <= 0x9fff then
            trace("send to warserver")
            if not skynet.try(function()
                ret = skynet.call(warserver, "lua", "recv_package", skynet.self(), 
                player.player_id, op, data) or 0
            end) then
                ret = errcode.Traceback
            else 
                --return
            end
        end
        assert(ret, string.format("no respone, opname %s", opname))
        if type(ret) == "table" then
            ret.err = ret.err or 0
        else
            ret = {err = ret} 
        end
        CMD.send_package(op, ret)
    end
}

function CMD.get_session()
    return session
end

function CMD.change_socket(conf)
    socket.close(player.conf.client)
    player.conf = conf
    player.is_online = true
    client = conf.client
    gate = conf.gate
    skynet.log("change_socket, %d", conf.client)
    skynet.call(gate, "lua", "forward", client)
    player:send_package(opcode.login.s2c_login, {err = 0, reconnected = true})
end

function CMD.is_online()
    if player and player.is_online then
        return true
    else
        return false
    end
end

function CMD.init_by_gameserver(conf)
    trace("agent start_game")
	client = conf.client
	gate = conf.gate
    
    local protobuf_env = skynet.call(conf.server, "lua", "get_protobuf_env")
    assert(type(protobuf_env) == "userdata")
    assert(not package.loaded["protobuf"])
    debug.getregistry().PROTOBUF_ENV = protobuf_env
    protobuf = require "protobuf"  

    player = require "gameserver.player"
    player.conf = conf
    player:load_module()
    player.gameserver:set(conf.server)
    player.send_package = function(player, op, data)
        local ret = skynet.try(function()
            CMD.send_package(op, data)
        end)
        if not ret then
            trace(util.dump(data))
            CMD.send_package(op, {err = errcode.Traceback})
        end
    end
    
    skynet.call(gate, "lua", "forward", client)
end

function CMD.init_by_loginserver(conf)
    trace("agent start_game")
	client = conf.client
	gate = conf.gate
    
    local protobuf_env = skynet.call(conf.server, "lua", "get_protobuf_env")
    assert(type(protobuf_env) == "userdata")
    assert(not package.loaded["protobuf"])
    debug.getregistry().PROTOBUF_ENV = protobuf_env
    protobuf = require "protobuf"  
        
    skynet.call(gate, "lua", "forward", client)
end

function CMD.bind_loginserver(addr)
    loginserver = addr
end

function CMD.bind_gameserver(addr)
    gameserver = addr
end

function CMD.bind_warserver(clustername, warname)
    warserver = cluster.proxy(clustername, warname)
    trace("bind_warserver %s %s", warname, warserver)
end


function CMD.send_package(op, tbl)
    tbl.err = tbl.err or 0

    assert(op, "op nil")
    assert(opcode.toname(op), string.format("op 0x%x not exist!", op))
    assert(tbl, "send data nil")
    
    if opcode.has_session(op) then
        session = session + 1
    end

    skynet.log("send_package 0x%x %s errcode:%s", op, opcode.toname(op), tbl.err)

    local data, len
    protobuf.encode(opcode.toname(op), tbl, function(buffer, bufferlen)
        data, len = packet.pack(op, session, buffer, bufferlen)
    end)
    
    socket.write(client, data, len)
    return NORET
end

function CMD.disconnect()
    trace("disconnect")
    if player and player.is_online then
        player:offline()
    end
    skynet.exit()
    return NORET
end

function CMD.kick()
    skynet.fork(function()
        skynet.exit()
    end)
end

function CMD.call_player(modulename, func, ...)
    trace("call_player %s, %s", modulename, func)
    if type(player[modulename]) == "function" then
        return player[modulename](player, ...)
    end
    return player[modulename][func](player[modulename], ...)
end

skynet.start(function()
	skynet.dispatch("lua", function(_,_, command1, command2, ...)
        local ret = NORET
		local f = CMD[command1]
        if f then
    		ret = f(command2, ...)
        elseif player[command1] then
            local module = player[command1]
            if type(module) == "function" then
                ret = module(player, command2, ...)
            else
                ret = module[command2](module, ...)
            end
        end
        if ret ~= NORET then
            skynet.ret(skynet.pack(ret))
        end
	end)

    prop:init()

    --loginserver = cluster.proxy("loginserver", ".loginserver")
    
end)

