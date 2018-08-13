local skynet = require "skynet"
local sname = require "sname"

local M = {}
function M.trace(sys)
    return function(fmt, ...)
        skynet.send(sname.LOG, "lua", "trace", sys, string.format(fmt, ...))
    end
end
function M.player(uid)
    return function(fmt, ...)
        skynet.send(sname.LOG, "lua", "player", uid, string.format(fmt, ...))
    end
end
function M.error(fmt, ...)
    skynet.send(sname.LOG, "lua", "error", string.format(fmt, ...))
end

return M
