local skynet = require "skynet"
local util = require "util"

local server_path, player_path = ...
assert(server_path) -- 服务器逻辑(xxx.xxxserver)
assert(player_path) -- 玩家逻辑(xxx.xxxplayer_t)

local server = require(server_path)

local GATE
local fd2acc = {}
local acc2agent = {}    -- 每个玩家对应的agent
local free_agents = {}  -- 空闲的agent addr -> true
local full_agents = {}  -- 满员的agent addr -> true

local PLAYER_PER_AGENT  -- 每个agent支持player最大值
local PROTO

local table_insert = table.insert
local table_remove = table.remove

local function create_agent()
    local agent = skynet.newservice("sock/agent", player_path)
    skynet.call(agent, "lua", "init", GATE, skynet.self(), PLAYER_PER_AGENT, PROTO)
    free_agents[agent] = true
    return agent
end

local SOCKET = {}
function SOCKET.open(fd, addr)
	skynet.error("New client from : " .. addr, fd)
    local agent
    for a, _ in pairs(free_agents) do
        agent = a
        break
    end
    if not agent then
        agent = create_agent()
    end
	local is_full = skynet.call(agent, "lua", "new_player", fd, addr)
    if is_full then
        free_agents[agent] = nil
        full_agents[agent] = true
    end
end

local function close_socket(fd)
    local acc = fd2acc[fd]
    local agent = acc2agent[acc]
    skynet.call(agent, "lua", "socket_close", acc, fd)
    skynet.call(GATE, "lua", "kick", fd)
    fd2acc[fd] = nil
end

function SOCKET.close(fd)
	print("socket close",fd)
    close_socket(fd)
end

function SOCKET.error(fd, msg)
	print("socket error",fd, msg)
    close_socket(fd)
end

function SOCKET.warning(fd, size)
	-- size K bytes havn't send out in fd
	print("socket warning", fd, size)
end

function SOCKET.data(fd, msg)
    print("socket data", fd, msg)
end

local CMD = {}
function CMD.start(conf)
    PLAYER_PER_AGENT = conf.player_per_agent or 100
    PROTO = conf.proto
    server:start()
    conf.preload = conf.preload or 10     -- 预加载agent数量
    skynet.call(GATE, "lua", "open" , conf)
    for i = 1, conf.preload do
        local agent = skynet.newservice("sock/agent", player_path)
        skynet.call(agent, "lua", "init", GATE, skynet.self(), PLAYER_PER_AGENT, PROTO)
        free_agents[agent] = true
    end
end
function CMD.set_free(agent)
    free_agents[agent] = true
    full_agents[agent] = nil
end

-- 上线后agent绑定acc，下线缓存一段时间
function CMD.player_online(agent, acc, fd)
    acc2agent[acc] = agent
    fd2acc[fd] = acc
end

-- 下线一段时间后调用
function CMD.free_player(agent, acc)
    acc2agent[acc] = nil
    free_agents[agent] = true
    full_agents[agent] = false
    print("&&&&& watchdog free_player")
end

function CMD.reconnect(fd, acc, passwd)
    local agent = acc2agent[acc] 
    if agent and skynet.call(agent, "lua", "reconnect", fd, acc, token) then
        return agent
    end
end

skynet.start(function()
	skynet.dispatch("lua", function(session, source, cmd, subcmd, ...)
        if cmd == "socket" then
            local f = SOCKET[subcmd]
            f(...)
            return
        elseif CMD[cmd] then
            util.ret(CMD[cmd](subcmd, ...))
        else
            local f = assert(server[cmd], cmd)
            if type(f) == "function" then
                util.ret(f(server, subcmd, ...))
            else
                util.ret(f[subcmd](f, ...))
            end
        end
    end)

   GATE = skynet.newservice("gate")
    
end)
