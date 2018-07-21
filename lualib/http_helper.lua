local skynet    = require "skynet"
local json      = require "cjson"

local webclient

local M = {}
function M.get(url, get)
    print("http get:", url, json.encode(get))
    webclient = webclient or skynet.newservice("web/webclient")
    return skynet.call(webclient, "lua", "request", url, get)
end

function M.post(url, post)
    print("http post:", url, post)
    webclient = webclient or skynet.newservice("web/webclient")
    return skynet.call(webclient, "lua", "request", url, nil, post)
end

function M.url_encoding(tbl)
    local data = {}
    for k, v in pairs(tbl) do
        table.insert(data, string.format("%s=%s", k, v))
    end
    return table.concat(data, "&")
end


return M
