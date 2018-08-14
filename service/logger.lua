-- 文件fd，保存一段时间，自动关闭
-- 系统log分系统存, 一天一份日志
-- 玩家log分uid存，一天一份日志
-- 所有的日志都会用skynet.error再输入一遍，终端模式下标准输出，或者写到skynet配置的logpath目录下
--

local skynet = require "skynet"
local date_helper = require "date_helper"
local conf = require "conf"

require "bash"

local logs = {} -- key(sys or uid) -> {last_time, file}
local CMD = {}
function CMD.trace(sys, str)
    local str = string.format("[%s][%s] %s", os.date("%H:%M:%S", os.time()), sys, str) 
    local log = logs[sys]
    if not log or date_helper.is_sameday(os.time(), log.last_time) then
        if log then
            log.file:close()
        end
        bash("mkdir -p %s/log/%s", conf.workspace, sys)
        local filename = string.format("%s/log/%s/%s.log", 
            conf.workspace, sys, os.date("%Y%m%d", os.time()))
        local file = io.open(filename, "a+")
        log = {file = file}
        logs[sys] = log
    end
    log.last_time = os.time()
    log.file:write(str.."\n")
    log.file:flush()

    skynet.error(str) 
end

function CMD.player(uid, str)
    local str = string.format("[%s][%d] %s", os.date("%H:%M:%S", os.time()), uid, str) 
    local log = logs[uid]
    if not log or date_helper.is_sameday(os.time(), log.last_time) then
        if log then
            log.file:close()
        end
        local dir = string.format("%d/%d/%d", uid//1000000, uid%1000000//1000, uid%1000)
        bash("mkdir -p %s/log/player/%s", conf.workspace, dir)
        local filename = string.format("%s/log/player/%s/%s.log", 
            conf.workspace, dir, os.date("%Y%m%d", os.time()))
        local file = io.open(filename, "a+")
        log = {file = file}
        logs[uid] = log
    end
    log.last_time = os.time()
    log.file:write(str.."\n")
    log.file:flush()

    skynet.error(str)
end

function CMD.error(str)
    local str = string.format("[%s] %s", os.date("%H:%M:%S", os.time()), str) 
    local file = io.open(string.format("%s/log/error.log", conf.workspace), "a+")
    file:write(str.."\n")
    file:flush()
    file:close()

    skynet.error(str)
end

skynet.start(function()
    skynet.dispatch("lua", function(_, _, cmd, ...)
        assert(CMD[cmd], cmd)(...)
        -- no return, don't call this service, use send
    end)
    skynet.fork(function()
        while true do
            local cur_time = os.time()
            for k, v in pairs(logs) do
                if cur_time - v.last_time > 3600 then
                    v.file:close()
                    logs[k] = nil
                end
            end
            skynet.sleep(100)
        end
    end)
end)
