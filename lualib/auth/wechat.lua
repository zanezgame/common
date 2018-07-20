-- 微信验证
local skynet = require "skynet"
local http = require "http_helper"
local json = require "cjson"
local M = {}
function M.check_code(js_code, appid, secret)
    local ret, resp = http.get("https://api.weixin.qq.com/sns/jscode2session",{
        appid = appid,
        secret = secret,
        js_code = js_code,
        grant_type = "authorization_code"
    })
    if ret then
        return json.decode(resp)
    end
end

function M.set_user_storage(access_token, openid, appid, signature, sig_method, kv_list)
    local ret, resp = http.post("") 
    if ret then
        return json.decode(resp)
    end
end

return M
