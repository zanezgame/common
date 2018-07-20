local skynet = require "skynet"

local webclient

local M = {}
function M.get(url, get)
    webclient = webclient or skynet.newservice("webclient")
    return skynet.call(webclient, "lua", "request", url, get)
end

function M.post(url, post)
    webclient = webclient or skynet.newservice("webclient")
    return skynet.call(webclient, "lua", "request", url, nil, post)
end

return M
