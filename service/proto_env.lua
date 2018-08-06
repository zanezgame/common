local skynet = require "skynet.manager"
local sname = require "sname"
local util = require "util"

local CMD = {}
function CMD.get_protobuf_env()
    return debug.getregistry().PROTOBUF_ENV
end
function CMD.register_file(path)
    local protobuf_c = require "protobuf.c"
    debug.getregistry().PROTOBUF_ENV = protobuf_c._env_new()
    local protobuf = require "protobuf"
    protobuf.register_file(path)
end

skynet.start(function()
    skynet.dispatch("lua", function(_,_,cmd, ...)
        local f = assert(CMD[cmd])
        util.ret(f(...))
    end)

end)
