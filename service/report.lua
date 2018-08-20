-- 向monitor节点报告本节点性能，状态等
--
local skynet = require "skynet"
local cluster = require "skynet.cluster"
local info = require "clusterinfo"
local conf = require "conf"
local util = require "util"
local log = require "log"
local print = log.print("report")

require "bash"

local function send(...)
    print("send", conf.clustername.monitor, ...)
    cluster.send("monitor", "svr", ...) 
end

local function call(...)
    print("call", conf.clustername.monitor, ...)
    cluster.call("monitor", "svr", ...)
end

local addr = conf.cluster.addr
local CMD = {}
function CMD.start()
    util.try(function()
        call("node_start", conf.cluster.name, conf.cluster.addr, conf.proj_name, 
            info.pnet_addr, info.inet_addr, info.pid)
    end)
    skynet.fork(function()
        while true do
            CMD.ping() 
            skynet.sleep(100)
        end
    end)
end

function CMD.ping()
    if not info.pid then
        return
    end
    
    local profile = info.profile 
    util.try(function()
        send("node_ping", addr, profile.cpu, profile.mem)
    end)
end

function CMD.stop()
    util.try(function()
        send("node_stop", addr)
    end)
end

skynet.start(function()
    skynet.dispatch("lua", function(_,_, cmd, ...)
        local f = assert(CMD[cmd], cmd)
        util.ret(f(...))
    end)
end)
