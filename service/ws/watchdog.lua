local skynet        = require "skynet"
local socket        = require "skynet.socket"
local httpd         = require "http.httpd"
local urllib        = require "http.url"
local json          = require "cjson"
local util          = require "util"

local server_path, player_path = ...
assert(server_path) -- 服务器逻辑(xxx.xxxserver)
assert(player_path) -- 玩家逻辑(xxx.xxxplayer)

local server = require(server_path)

local socks = {}        -- id:ws
local uid2agent = {}    -- 每个账号对应的agent
local free_agents = {}  -- 空闲的agent addr -> true
local full_agents = {}  -- 满员的agent addr -> true

local PLAYER_PER_AGENT  -- 每个agent支持player最大值
local PROTO


local table_insert = table.insert
local table_remove = table.remove

local function create_agent()
    local agent
    for a, _ in pairs(free_agents) do
        agent = a
        break
    end
    if not agent then
        agent = skynet.newservice("ws/agent", player_path)
        skynet.call(agent, "lua", "init", skynet.self(), PLAYER_PER_AGENT, PROTO)
        free_agents[agent] = true
    end
    return agent
end

local CMD = {}
function CMD.start(conf)
    PLAYER_PER_AGENT = conf.player_per_agent or 100
    PROTO = conf.proto

    server:start()

    preload = conf.preload or 10     -- 预加载agent数量
    for i = 1, preload do
        create_agent()
    end

    local address = "0.0.0.0:"..conf.port
    skynet.error("Listening "..address)
    local fd = assert(socket.listen(address))
    socket.start(fd , function(fd, addr)
        local agent
        for a, _ in pairs(free_agents) do
            agent = a
            break
        end
        if not agent then
            agent = create_agent()
        end
        skynet.call(agent, "lua", "new_player", fd)
    end)
end

-- 上线后agent绑定uid，下线缓存一段时间
function CMD.player_online(agent, uid)
    uid2agent[uid] = agent
end

-- 下线一段时间后调用
function CMD.player_destroy(agent, uid)
    uid2agent[uid] = nil
    free_agents[agent] = true
    full_agents[agent] = false
end


skynet.start(function()
    skynet.dispatch("lua", function(_, _, cmd1, ...)
        local f = CMD[cmd1] or server[cmd1]
        assert(f, cmd1)
        util.ret(f(...))
    end)
end)
