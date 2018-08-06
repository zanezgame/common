-- 一些通用服务名
local skynet = require "skynet.manager"
local reg = {
    WEB = "web/webclient",
    PROTO = "proto_env",
    REDIS = "db/redisd",
    MONGO = "db/mongod",
}

local M = {}
setmetatable(M, {
    __index = function (t, k)
        local name = assert(reg[k], string.format("sname %s not exist", k))
        return skynet.uniqueservice(name)
    end,
    __newindex = function ()
        assert("cannot overwrite sname")
    end
})

return M
