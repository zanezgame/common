local skynet    = require "skynet"
local sname     = require "sname"

local M = {}
setmetatable(M, {
    __index = function(t, k)
        local v = rawget(t, k)
        if v then
            return v
        else
            return function(...)
                return skynet.call(sname.REDIS, "lua", k, ...)
            end
        end
    end
})

function M.auto_id()
    local auto_id = M.get("auto_id") or "10000" 
    auto_id = tonumber(auto_id)//1 + 1
    M.set("auto_id", auto_id)
    return auto_id
end

return M
