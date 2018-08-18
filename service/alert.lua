-- 钉钉警报系统
local skynet = require "skynet"
local http = require "web.http_helper"
local util = require "util"
local conf = require "conf"
local log = require "log"
local json = require "cjson"
local trace = log.trace("alert")
require "bash"

local host = "https://oapi.dingtalk.com"
local function get_token()
    local ret, resp = http.get(host.."/gettoken", {corpid = conf.alert.corpid, corpsecret = conf.alert.corpsecret})
    if ret then
        local data = json.decode(resp)
        return data.access_token
    else
        skynet.error("cannot get token")
    end 
end

local CMD = {}
function CMD.traceback(err)
    --[[local ret, resp = http.post(host.."/message/send_to_conversation?access_token="..token, json.encode {
        sender = "manager3375",
        cid ="dcb66a48183e3cfe8fbce9207c3ecec9",
        msgtype = "text",
        text = { 
            content = str
        }   
    })
    print(ret, resp)]]
    local info = require "clusterinfo"
    local path = string.format("%s/log/%s.log", info.workspace, skynet.getenv("clustername") or "error")
    local str = string.format("服务器Traceback\n项目:%s\n节点:%s\n公网ip:%s\n内网ip:%s\n进程:%s\n路径:%s\n自己上去看log，傻逼!",
        info.proj_name, info.clustername, info.pnet_addr, info.inet_addr, info.pid, path)
    --print(str)
    CMD.test(str) 
end

function CMD.test(str)
    -- 暂时先用curl发https post
    local token = get_token()
    local sh = string.format('curl -H "Content-Type:application/json" -X POST -d \'%s\' %s/chat/send?access_token=%s', json.encode {
        sender = conf.alert.sender,
        chatid = conf.alert.chatid,
        msgtype = "text",
        text = { 
            content = str,
        } 
    }, host, token)
    print(sh)
    bash(sh)

end

function CMD.get_userid(code)
    local ret, resp = http.get(host.."/user/getuserinfo", {token = get_token(), code = code})
    if ret then
        local data = json.decode(resp)
        return data.userid
    else
        skynet.error("userid")
    end
end

skynet.start(function()
    skynet.dispatch("lua", function(_,_, cmd, ...)
        local f = assert(CMD[cmd], cmd)
        util.ret(f(...))
    end)
end)
