local skynet = require "skynet"
local util = require "util"
local log = require "log"
local trace = log.trace("gm")

local skynet_cmd = {}
local gmcmd = {
    skynet = skynet_cmd,
}

local CMD = {}
function CMD.add_gmcmd(modname, gmcmd_path)
    gmcmd[modname] = require(gmcmd_path)
end

function CMD.run(modname, cmd, ...)
    local mod = gmcmd[modname]
    if not mod then
        return string.format("模块[%s]未初始化", modname)
    end
    local f = mod[cmd]
    if not f then
        return string.format("GM指令[%s][%s]不存在", modname, cmd)
    end
    local args = {...}
    local ret
    if not util.try(function()
        ret = f(table.unpack(args))
    end) then
        return "服务器执行Traceback了"
    end
    return ret or "执行成功"
end

local hotfix_addrs = {}
function CMD.reg_hotfix(addr)
    trace("reg_hotfix:%s", addr)
    hotfix_addrs[addr] = true 
end

function CMD.unreg_hotfix(addr)
    hotfix_addrs[addr] = nil
end

skynet.start(function()
    skynet.dispatch("lua", function(_,_, cmd, ...)
        local f = assert(CMD[cmd], cmd)
        util.ret(f(...))
    end)
end)

function skynet_cmd.list()
    local list = {}
    local all = skynet.call(".launcher", "lua", "LIST")
    for addr, desc in pairs(all) do
        table.insert(list, {addr = addr, desc = desc})
    end

    for i, v in ipairs(list) do
        local addr = v.addr
        v.mem = skynet.call(addr, "debug", "MEM")
        if v.mem < 1024 then
            v.mem = math.floor(v.mem).." Kb"
        else
            v.mem = math.floor(v.mem/1024).." Mb"
        end

        local stat = skynet.call(addr, "debug", "STAT")
        v.task = stat.task
        v.mqlen = stat.mqlen
        v.id = i
        v.address = skynet.address(addr)
    end
    table.sort(list, function(a, b)
        return a.addr < b.addr
    end)
    local str = ""
    for i, v in ipairs(list) do
        str = str .. string.format("地址:%s 内存:%s 消息队列:%s 请求量:%s 启动命令:%s\n", 
            v.addr, v.mem, v.mqlen, v.task, v.desc)
    end
    return str
end

function skynet_cmd.hotfix()
    trace("gm hotfix")    
    for addr, _ in pairs(hotfix_addrs) do
        skynet.send(addr, "lua", "hotfix")
    end
end
