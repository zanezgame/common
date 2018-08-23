local skynet = require "skynet"
local sname = require "sname"

local M = {}
function M.add_gmcmd(modname, gmcmd_path)
    skynet.call(sname.GM, "lua", "init", modname, gmcmd_path)
end

function M.run(...)
    return skynet.call(sname.GM, "lua", "run", ...)
end

-- 注册热更，需要处理hotfix这个消息
function M.reg_hotfix()
    skynet.send(sname.GM, "lua", "reg_hotfix", skynet.self())
end

function M.unreg_hotfix()
    skynet.send(sname.GM, "lua", "unreg_hotfix", skynet.self())
end
return M
