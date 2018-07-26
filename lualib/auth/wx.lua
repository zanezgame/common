--  微信验证
--  每个需要用到的服务都需要在启动的时候调wx.init
--

local skynet    = require "skynet"
local http      = require "web.http_helper"
local json      = require "cjson"
local sha256    = require "auth.sha256"
local datacenter= require "skynet.datacenter"

local M = {}

function M:init(appid, secret)
    self.appid = appid
    self.secret = secret

    self:request_access_token()
end

function M:request_access_token()
    local ret, resp = http.get("https://api.weixin.qq.com/cgi-bin/token", {
        grant_type = "client_credential",
        appid = self.appid,
        secret = self.secret,
    }) 
    if ret then
        resp = json.decode(resp)
        self.access_token = resp.access_token
        self.access_exires_in = resp.expires_in
        self.access_time = os.time()
    else
        error(resp)
    end
end

function M:get_access_token()
    if os.time() - self.access_time > self.access_exires_in then
        M:request_access_token()
    end
    return self.access_token
end

function M:check_code(js_code)
    local ret, resp = http.get("https://api.weixin.qq.com/sns/jscode2session",{
        js_code = js_code,
        grant_type = "authorization_code",
        appid = self.appid,
        secret = self.secret,
    })
    if ret then
        return json.decode(resp)
    else
        error(resp)
    end
end

-- data {score = 100, gold = 300}
function M:set_user_storage(openid, session_key, data)
    local kv_list = {}
    for k, v in pairs(data) do
        table.insert(kv_list, {key = k, value = v})
    end
    local post = json.encode({kv_list = kv_list})
    local url = "https://api.weixin.qq.com/wxa/set_user_storage?"..http.url_encoding({
        access_token = M:get_access_token(),
        openid = openid,
        appid = self.appid,
        signature = sha256.hmac_sha256(post, session_key),
        sig_method = "hmac_sha256", 
    })
    local ret, resp = http.post(url, post)
    if ret then
        return json.decode(resp)
    else
        error(resp)
    end
end

-- key_list {"score", "gold"}
function M:remove_user_storage(openid, session_key, key_list)
    local post = json.encode({key = key_list})
    local url = "https://api.weixin.qq.com/wxa/remove_user_storage?"..http.url_encoding({
        access_token = M:get_access_token(),
        openid = openid,
        appid = self.appid,
        signature = sha256.hmac_sha256(post, session_key),
        sig_method = "hmac_sha256", 
    })
    local ret, resp = http.post(url, post)
    if ret then
        return json.decode(resp)
    else
        error(resp)
    end
end



setmetatable(M, {
    __index = function(t, k)
        return assert(datacenter.get("wx", k))
    end,
    __newindex = function(t, k, v)
        datacenter.set("wx", k, v)
    end,
})

return M
