local skynet        = require "skynet"
local util          = require "util"

local uid2info = {} -- uid -> info {uid, value, agent}
local values = {} -- value -> uids

local MODE       -- 匹配模式
local MAX_TIME   -- 匹配时长
local MAX_RANGE  -- 匹配最大范围

local CMD = {}
function CMD.init(mode, max_time, max_range)
    MODE = mode
    MAX_TIME = max_time or 3
    MAX_RANGE = max_range or 0
end

function CMD.start(uid, value, agent)
    --print("start match", uid, value)
    if uid2info[uid] then
        skynet.error(uid, "is matching")
        return
    end
    uid2info[uid] = {
        uid = uid,
        value = value,
        agent = agent,
        ret = -1, -- -1:未匹配到对手 0:机器人 >0:玩家uid
    }
    values[value] = values[value] or {}
    values[value][uid] = os.time()
end

function CMD.cancel(uid)
    local info = uid2info[uid]
    if not info then
        skynet.error(uid, "not matching")
        return
    end
    uid2info[uid] = nil
end

-- 最粗暴的匹配算法
local function update()
    --print("match update")
    local cur_time = os.time()
    for uid, info in pairs(uid2info) do
        local value = info.value
        if cur_time - values[value][uid] > MAX_TIME then
            info.ret = 0
        else
            local list = {values[value]}
            for i = 1, MAX_RANGE do
                list[#list+1] = values[value - i]
                list[#list+1] = values[value + i]
            end
            for _, vs in pairs(list) do
                for u, _ in pairs(vs) do
                    if uid2info[u].ret < 0 and u ~= uid then
                        uid2info[u].ret = uid
                        info.ret = u
                        break
                    end
                end
                if info.ret >= 0 then
                    break
                end
            end
        end
    end

    for uid, info in pairs(uid2info) do
        if info.ret >= 0 then
            local id1 = uid
            local id2 = info.ret
            skynet.call(info.agent, "lua", uid, "battle", "matched", MODE, info.ret)
            uid2info[uid] = nil
            values[info.value][uid] = nil
        end
    end
end

skynet.start(function()
    skynet.dispatch("lua", function(_, _, cmd, ...)
        local f = assert(CMD[cmd], cmd)
        util.ret(f(...))
    end)

    skynet.fork(function()
        while true do
            update() 
            skynet.sleep(10)
        end
    end)
end)
