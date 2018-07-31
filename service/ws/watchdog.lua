local skynet        = require "skynet"
local socket        = require "skynet.socket"
local httpd         = require "http.httpd"
local urllib        = require "http.url"
local sockethelper  = require "http.sockethelper"
local json          = require "cjson"
local util          = require "util"

local server, player = ...
assert(server) -- 服务器逻辑(xxx.xxxserver)
assert(player) -- 玩家逻辑(xxx.xxxplayer)

local server = require(server)

local socks = {}     -- id:ws
local fd2agent = {}  -- socket对应的agent
local acc2agent = {} -- 每个账号对应的agent
local free_list = {} -- 空闲的agent list
local send_type

local table_insert = table.insert
local table_remove = table.remove

local function pop_free_agent()
    local agent = free_list[#free_list]
    if not agent then
        return skynet.newservice("ws/agent", player)
    end
    free_list[#free_list] = nil
    return agent
end

local CMD = {}
function CMD.start(conf)
    util.init_proto_env(conf.proto)
    server:start()

    preload = conf.preload or 10     -- 预加载agent数量
    for i = 1, preload do
        local agent = skynet.newservice("ws/agent", player)
        table_insert(free_list, agent)
    end

    local address = "0.0.0.0:"..conf.port
    skynet.error("Listening "..address)
    local fd = assert(socket.listen(address))
    socket.start(fd , function(fd, addr)
       local agent = pop_free_agent()
       skynet.call(agent, "lua", "start", skynet.self(), fd, send_type)
       fd2agent[fd] = agent
    end)
end

-- 上线后agent绑定acc，下线缓存一段时间
function CMD.bind_acc(agent, acc)
    acc2agent[acc] = agent
end

-- 下线一段时间后调用
function CMD.free_agent(acc, agent)
    table_insert(free_list, agent) 
    acc2agent[acc] = nil
end


skynet.start(function()
    skynet.dispatch("lua", function(_, _, cmd1, ...)
        local f = CMD[cmd1] or server[cmd1]
        assert(f, cmd1)
        util.ret(f(...))
    end)
end)
