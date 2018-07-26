local skynet    = require "skynet"
local util      = require "util"

local room = ...
local room = require(room)

local CMD = {}
function CMD.start(watchdog)
    room:init(watchdog)
end

skynet.start(function()
    skynet.dispatch("lua", function(_, _, cmd1, cmd2, ...)
        local f = CMD[cmd1]
        if f then
            util.ret(f(cmd2, ...))
        elseif room[cmd1] then
            local module = player[cmd1]
            if type(module) == "function" then
                util.ret(module(player, cmd2, ...))
            else
                util.ret(module[cmd2](module, ...))
            end
        end
    end)
end)

