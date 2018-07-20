-- 微信验证
local skynet = require "skynet"
local http = require "http_helper"
local M = {}
function M.check_code(js_code, appid, secret)
   return http.get("https://api.weixin.qq.com/sns/jscode2session",{
        appid = appid,
        secret = secret,
        js_code = js_code,
        grant_type = "authorization_code"
    })
end

return M
