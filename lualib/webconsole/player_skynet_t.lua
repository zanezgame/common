local skynet = require "skynet"
local class = require "class"
local util = require "util"
local conf = require "conf"
local log = require "log"
local gm = require "gm"

local trace = log.trace("webconsole")

local M = class("player_skynet_t")
function M:ctor(player)
    self.player = player
end

local function debug_call(addr, cmd, ...)
    return skynet.call(addr, "debug", cmd, ...)
end

local function debug_send(addr, cmd, ...)
    return skynet.send(addr, "debug", cmd, ...)
end

function M:c2s_all_service()
    local list = {} 
    
    local all = skynet.call(".launcher", "lua", "LIST")
    for addr, desc in pairs(all) do
        table.insert(list, {addr = addr, desc = desc})
    end
    

    for i, v in ipairs(list) do
        local addr = v.addr
        v.mem = debug_call(addr, "MEM")
        if v.mem < 1024 then
            v.mem = math.floor(v.mem).." Kb"
        else
            v.mem = math.floor(v.mem/1024).." Mb"
        end

        local stat = debug_call(addr, "STAT")
        v.task = stat.task
        v.mqlen = stat.mqlen
        v.id = i
        v.address = skynet.address(addr)
    end
    table.sort(list, function(a, b)
        return a.addr < b.addr
    end)
    return {service_list = list}
end

function M:c2s_node_config()
    local info = require "clusterinfo"
    local profile = info.profile
    return {
        proj_name = conf.proj_name,
        clustername = conf.cluster.name,
        pnet_addr = info.pnet_addr,
        inet_addr = info.inet_addr,
        pid = info.pid,
        profile = profile and string.format("CPU:%sMEM:%.fM", profile.cpu, profile.mem/1024),
        gate = conf.gate and string.format("%s:%s", conf.gate.host, conf.gate.port),
        webconsole = conf.webconsole and string.format("%s:%s", conf.webconsole.host, conf.webconsole.port),
        mongo = conf.mongo and string.format("%s:%s[%s]", conf.mongo.host, conf.mongo.port, conf.mongo.name),
        redis = conf.redis and string.format("%s:%s", conf.redis.host, conf.redis.port),
        mysql = conf.mysql and string.format("%s:%s[%s]", conf.mysql.host, conf.mysql.port, conf.mysql.name),
        alert_enable = conf.alert and conf.alert.enable,
    }
end

function M:c2s_get_blacklist()
    trace("get_blacklist")
    local list = require "ip.blacklist"
    return {list = table.concat(list.list(), "\n")}
end

function M:c2s_set_blacklist(data)
    trace("set_blacklist")
    local list = require "ip.blacklist"
    list.clear()
    for ip in string.gmatch(data.list, "[^\n]+") do
        trace("add black ip:%s", ip)
        list.add(ip)
    end
end

function M:c2s_get_whitelist()
    trace("get_blacklist")
    local list = require "ip.whitelist"
    return {list = table.concat(list.list(), "\n")}
end

function M:c2s_set_whitelist(data)
    trace("set_blacklist")
    local list = require "ip.whitelist"
    list.clear()
    for ip in string.gmatch(data.list, "[^\n]+") do
        trace("add black ip:%s", ip)
        list.add(ip)
    end
end

function M:c2s_run_gm(data)
    local args = {}
    for arg in string.gmatch(data.cmd, "[^ ]+") do
        table.insert(args, arg)
    end
    local modname = args[1]
    local cmd = args[2]
    if not modname or not cmd then
        return {ret = "格式错误"}
    end
    table.remove(args, 1)
    table.remove(args, 1)
    return {ret = gm.run(modname, cmd, table.unpack(args))}
end

return M
