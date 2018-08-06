local skynet        = require "skynet"
local util          = require "util"

local CMD = {}
function CMD.init(mod)
end

skynet.start(function()
    skynet.dispatch("lua", function(_, _, cmd, ...)
        local f = assert(CMD[cmd], cmd)
        util.ret(f(...))
    end)
end)
