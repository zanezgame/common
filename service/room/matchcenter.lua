local skynet = require "skynet"
local util = require "util"

local addrs = {} -- mode -> service

local CMD = {}
function CMD.add_mode(mode, max_time, max_range)
    assert(not addrs[mode])
    addrs[mode] = skynet.newservice("room/match")
    skynet.call(addrs[mode], "lua", "init", mode, max_time, max_range)
end

function CMD.match(mode, uid, value, agent)
    local addr = assert(addrs[mode])
    skynet.call(addr, "lua", "start", uid, value, agent)
end

skynet.start(function()
    skynet.dispatch("lua", function(_, _, cmd, ...)
        local f = assert(CMD[cmd], cmd)
        util.ret(f(...))
    end)
end)
