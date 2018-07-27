-- 一些通用服务名
local skynet = require "skynet.manager"
local reg = {
    WEB = {".webclient",  "web/webclient"},
    PROTO = {".proto_env",  "proto_env"},
}

local M = {}
function M.start(servicename, ...)
    local script
    for _, v in pairs(reg) do
        if v[1] == servicename then
            script = v[2]
            break
        end
    end
    assert(script)
    local service = skynet.newservice(script, ...)
    skynet.name(servicename, service)
end

setmetatable(M, {
    __index = function (t, k)
        return assert(reg[k], string.format("sname %s not exist", k))[1]
    end,
    __newindex = function ()
        assert("cannot overwrite sname")
    end
})

return M
