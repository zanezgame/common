local skynet = require "skynet.manager"
local cluster = require "skynet.cluster"
local protobuf_c = require "protobuf.c"
local config = require "config"
local errcode = require "define.errcode"
local db = require "common.db"
local util = require "common.util"
local os_utility = require "common.os_utility"
local date_utility = require "common.date_utility"
local prop = require "prop"
local gmcmd = require "gameserver.gm.gmcmd"

local gate
local agent2fd = {}
local server_id = 0
local server_name = ""
local id2agent = {}       
local id2player = {}
local agent2player = {}
local account2agent = {}

local NORET = "NORET"
local trace = util.trace("gameserver")

local function init_protobuf()
    debug.getregistry().PROTOBUF_ENV = protobuf_c._env_new()
    local protobuf = require "protobuf"
    protobuf.register_file(config.workspace .. "/script/define/proto/package.pb")
end

local gameserver = {
}

function gameserver:get_protobuf_env()
    return debug.getregistry().PROTOBUF_ENV
end

function gameserver:reload()
    for player_id,agent in pairs(account2agent) do
        skynet.call(agent, "lua", "reload_player")
    end
end

function gameserver:send_to_world(op, data)
    for player_id,agent in pairs(account2agent) do
        local clone_data = {}
        for k,v in pairs(data) do
            clone_data[k] = v
        end
        skynet.send(agent, "lua", "send_package", op, clone_data)
    end
    return 0
end

function gameserver:send_to_player(op, data, player_id)
    local agent = id2agent[player_id]
    if not agent then
        return errcode.PlayerOffline
    end
    skynet.send(agent, "lua", "send_package", op, data)
    return 0
end

function gameserver:broadcast(...)
    local args = table.pack(...)
    skynet.try(function()
        for _, agent in pairs(account2agent) do
            skynet.send(agent, "lua", table.unpack(args))
        end
    end)
end

function gameserver:call_player(player_id, ...)
    local agent = id2agent[player_id]
    if not agent or not skynet.call(agent, "lua", "is_online") then
        return errcode.PlayerOffline
    end
    return skynet.call(agent, "lua", "call_player", ...)
end

function gameserver:agent_create(player_id, account, agent)

end

function gameserver:player_online(account, player_id, agent)
    account2agent[account] = agent
    id2agent[player_id] = agent
end

function gameserver:player_offline(account, player_id)
    account2agent[account] = nil
    id2agent[player_id] = nil
end

function gameserver:get_agent_by_player_id(player_id)
    return id2agent[player_id]
end

function gameserver:get_agent_by_account(account)
    return account2agent[account]
end

function gameserver:server_id()
    return server_id
end

function gameserver:new_open()
end

function gameserver:get_online_count()
    local count = 0
    for k, v in pairs(agent2fd) do
        count = count + 1
    end
    return count
end

function gameserver:get_detail_data()
    local data = {
        server_name = server_name,
        online_count = self:get_online_count(),
    } 
    return data
end

local log_file_name
local log_file
local function _log(format, ...)
    local str = "["..os.date("%H:%M:%S", os.time()).."]"..string.format(format, ...)
    local new_file_name = config.workspace.."/log/gameserver/"..server_id
        .."/"..os.date("%Y%m%d", os.time())..".log"
    if log_file_name ~= new_file_name then
        if log_file then
            log_file:close()
        end
        os_utility.create_folder(config.workspace.."/log/gameserver/"..server_id)
        log_file = io.open(new_file_name, "a+")
        log_file_name = new_file_name
    end    
    log_file:write(str.."\n")
    log_file:flush()

    skynet.error(str)
end

local SOCKET = {}
function SOCKET.open(fd, addr)
    trace("New client from : " .. addr)
    agent2fd[fd] = skynet.newservice("agent")
    skynet.call(agent2fd[fd], "lua", "init_by_gameserver", {gate = gate, client = fd, server = skynet.self()})
    skynet.call(agent2fd[fd], "lua", "bind_gameserver", skynet.self())
end

local function close_agent(fd)
    local a = agent2fd[fd]
    agent2fd[fd] = nil
    if a then
        skynet.call(gate, "lua", "kick", fd)
        skynet.send(a, "lua", "disconnect")
    end
end

function SOCKET.close(fd)
    trace("socket close",fd)
    close_agent(fd)
end

function SOCKET.error(fd, msg)
    trace("socket error",fd, msg)
    close_agent(fd)
end

function SOCKET.warning(fd, size)
    trace("socket warning", fd, size)
end

function SOCKET.data(fd, msg)
    trace("socket data")
end

function gameserver:start(conf)
    prop:init()
    skynet.call(gate, "lua", "open", conf)
    server_id = conf.id
    server_name = conf.name
   
    local data = db.find_one_with_default("gameserver", 
        {server_id = server_id}, {server_id = server_id})

    skynet.log = _log
    skynet.log("gameserver start !!!!")

    db.disconnect()
end

function gameserver:stop()
    skynet.log("gameserver %d will be stop", server_id)
    skynet.try(function()
        gameserver:save()
        skynet.abort()
        return NORET
    end)
end

function gameserver:abort()
    skynet.log("gameserver %d will be stop", server_id)
    gameserver:save()
    skynet.timeout(0, function()
        skynet.abort() 
    end)
end

function gameserver:save()
    for _, agent in pairs(account2agent) do
        skynet.try(function()
            skynet.call(agent, "lua", "call_player", "save")
        end)
    end

    skynet.log("gameserver %d saved", server_id)
end

function gameserver:close(fd)
    close_agent(fd)
end

function gameserver:execute_gm(cmd, ...)
    return gmcmd[cmd](skynet.self(), ...) 
end

function gameserver:point_logic()
    for _, agent in pairs(account2agent) do
        skynet.send(agent, "lua", "point_logic")
    end
    
    local hour = date_utility.hour()
    skynet.log("gameserver point_logic, %d", hour)
    local func = self["point_logic_"..hour]
    if func then
        func(self)
    end

    self:save()
   
    return NORET
end

function gameserver:point_logic_23()
end

function gameserver:init_cluster()
    local clustername = skynet.getenv("clustername")
    skynet.register("."..clustername)         
    cluster.open(clustername)

    local server_idx = tonumber(string.match(clustername, "%d+"))
    local conf = cluster.call("master", ".server_manager", "on_gameserver_start", server_idx, clustername)
    self:start(conf)
end

skynet.start(function()
    skynet.dispatch("lua", function(session, source, cmd, subcmd, ...)
        --trace("%s, %s", cmd, subcmd)
        local function ret_value(noret, ...)
            if noret ~= NORET then
                skynet.log("%s %s", cmd, noret)
                skynet.ret(skynet.pack(noret, ...))
            end
        end

        local ret = NORET
        if cmd == "socket" then
            local f = SOCKET[subcmd]
            f(...)
            return
        else
            local f = assert(gameserver[cmd], cmd)
            if type(f) == "function" then
                ret_value(f(gameserver, subcmd, ...))
            else
                ret_value(f[subcmd](f, ...))
            end
        end
    end)

    init_protobuf()

    gate = skynet.newservice("gate")

    loginserver = cluster.proxy("loginserver", ".loginserver")

    gameserver:init_cluster()
end)



