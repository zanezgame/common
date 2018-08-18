local skynet = require "skynet"

local M = {}
function M.trace(sys)
    return function(fmt, ...)
        skynet.send(".logger", "lua", "trace", skynet.self(), sys, string.format(fmt, ...))
    end
end

function M.print(sys)
    return function(...)
        skynet.send(".logger", "lua", "trace", skynet.self(), sys, table.concat(table.pack(...), ' '))
    end
end

function M.player(uid)
    return function(fmt, ...)
        skynet.send(".logger", "lua", "player", skynet.self(), uid, string.format(fmt, ...))
    end
end

return M
