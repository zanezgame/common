local skynet = require "skynet.manager"
local redis = require "skynet.db.redis"
local sname = require "sname"
local util = require "util"
local conf = require "conf"

local mod = ...

if mod == "agent" then

local db
skynet.start(function()
    db = redis.connect(conf.redis)
    skynet.dispatch("lua", function(_, _, cmd, ...)
        util.ret(db[cmd](db, ...))
    end)
end)

else

skynet.start(function()
    local preload = conf.preload or 10
    local agent = {}
    for i = 1, preload do
        agent[i] = skynet.newservice(SERVICE_NAME, "agent")
    end
    local balance = 1
    skynet.dispatch("lua", function(_,source, ...)
        balance = balance + 1
        if balance > #agent then
            balance = 1
        end
        local ret = skynet.call(agent[balance], "lua", ...)
        util.ret(ret)
    end)
end)

end
