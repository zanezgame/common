local skynet = require "skynet.manager"
local mysql = require "skynet.db.mysql"
local sname = require "sname"
local util = require "util"
local conf = require "conf"

local mod = ...

if mod == "agent" then

local db
skynet.start(function()
    local function on_connect(db)
        db:query("set charset utf8");
    end
    db=mysql.connect({
        host=conf.mysql.host,
        port=conf.mysql.port,
        database=conf.mysql.name,
        user=conf.mysql.user,
        password=conf.mysql.password,
        max_packet_size = 1024 * 1024,
        on_connect = on_connect
    })
    skynet.dispatch("lua", function(_, _, cmd, ...)
        local f = assert(db[cmd])
        util.ret(f(db, ...))
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
