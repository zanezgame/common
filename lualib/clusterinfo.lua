-- 集群节点相关信息
-- 访问方式 clusterinfo.xxx or clusterinfo.get_xxx()
--
local skynet = require "skynet"
local http = require "web.http_helper"
local conf = require "conf"
require "bash"

local M = {}
local _cache = {}
setmetatable(M, {
    __index = function (t, k)
        local v = rawget(t, k) 
        if v then
            return v
        end
        local f = rawget(t, '_'..k)
        if f then
            v = _cache[k] or f()
            _cache[k] = v
            return v
        end
        f = rawget(t, 'get_'..k)
        assert(f, "no clusterinfo "..k)
        return f()
    end
})

-- 公网ip
function M._pnet_addr()
    local ret, resp = http.get('http://members.3322.org/dyndns/getip')
    local addr = string.gsub(resp, "\n", "")
    return addr
end

-- 内网ip
function M.get_inet_addr()
    local ret = bash "ifconfig eth0" 
    return string.match(ret, "inet addr:([^%s]+)")
end

function M.get_run_time()

end

-- 进程pid
function M._pid()
    local filename = skynet.getenv "daemon"
    if not filename then
        return
    end
    local pid = bash("cat %s", filename)
    return string.gsub(pid, "\n", "")
end

function M._proj_name()
    return conf.proj_name
end

function M._clustername()
    return skynet.getenv "clustername"
end

-- 绝对路径
function M._workspace()
    local path = bash("cd %s && pwd", conf.workspace)
    return string.gsub(path, "\n", "")
end


return M
