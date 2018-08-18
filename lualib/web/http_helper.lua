-- Http 请求 get post
--
local skynet    = require "skynet"
local json      = require "cjson"
local sname     = require "sname"
require "bash"

local M = {}
function M.get(url, get)
    skynet.error("http get:", url, json.encode(get))
    return skynet.call(sname.WEB, "lua", "request", url, get)
end

function M.post(url, post)
    skynet.error("http post:", url, post)
    return skynet.call(sname.WEB, "lua", "request", url, nil, post)
end

function M.url_encoding(tbl)
    local data = {}
    for k, v in pairs(tbl) do
        table.insert(data, string.format("%s=%s", k, v))
    end
    return table.concat(data, "&")
end

-- 公网ip
function M.pnet_addr()
    local ret, resp = M.get('http://members.3322.org/dyndns/getip')
    local addr = string.gsub(resp, "\n", "")
    return addr
end

-- 内网ip
function M.inet_addr()
    local ret = bash "ifconfig eth0" 
    return string.match(ret, "inet addr:([^%s]+)")
end

return M
