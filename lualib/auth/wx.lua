-- 微信验证
-- 每个需要用到的服务都需要在启动的时候调wx.init
--
local skynet    = require "skynet"
local http      = require "http_helper"
local json      = require "cjson"
local sha256    = require "auth.sha256"

local appid
local secret
local access_token
local access_time = 0       -- access_token 更新时间戳
local access_exires_in = 0 -- access_token 有效时间

local M = {}
function M.init(id, sec)
    appid = id
    secret = sec

    M.request_access_token()
end

function M.request_access_token()
    assert(appid and secret)
    local ret, resp = http.get("https://api.weixin.qq.com/cgi-bin/token", {
        grant_type = "client_credential",
        appid = appid,
        secret = secret,
    }) 
    if ret then
        resp = json.decode(resp)
        access_token = resp.access_token
        access_exires_in = resp.expires_in
        access_time = os.time()
    else
        error(resp)
    end
end

function M.get_access_token()
    if os.time() - access_time > access_exires_in then
        M.request_access_token()
    end
    return access_token
end

function M.check_code(js_code)
    assert(appid and secret)
    local ret, resp = http.get("https://api.weixin.qq.com/sns/jscode2session",{
        js_code = js_code,
        grant_type = "authorization_code",
        appid = appid,
        secret = secret,
    })
    if ret then
        return json.decode(resp)
    else
        error(resp)
    end
end

function M.set_user_storage(openid, session_key, data)
    assert(appid and secret)
    local kv_list = {}
    for k, v in pairs(data) do
        table.insert(kv_list, {key = k, value = v})
    end
    local post = json.encode({kv_list = kv_list})
    local url = "https://api.weixin.qq.com/wxa/set_user_storage?"..http.url_encoding({
        access_token = M.get_access_token(),
        openid = openid,
        appid = appid,
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

return M
