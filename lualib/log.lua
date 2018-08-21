local skynet = require "skynet"

local tostring = tostring
local select   = select

local M = {}
function M.trace(sys)
    return function(fmt, ...)
        skynet.send(".logger", "lua", "trace", skynet.self(), sys, string.format(fmt, ...))
    end
end

function M.print(sys)
    return function(...)
        local args = {}
        for i = 1, select('#', ...) do
            args[i] = tostring(select(i, ...))
        end
        local str = table.concat(args, " ")
        skynet.send(".logger", "lua", "trace", skynet.self(), sys, str)
    end
end

function M.player(uid)
    return function(fmt, ...)
        skynet.send(".logger", "lua", "player", skynet.self(), uid, string.format(fmt, ...))
    end
end

return M
