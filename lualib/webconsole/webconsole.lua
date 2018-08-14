local skynet = require "skynet"
local log = require "log"

local trace = log.trace("webconsole")

local M = {}
function M:start()
    trace("webconsole start!") 
end

return M
