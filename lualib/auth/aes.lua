local caes = require "caes"
local aes = {}
function aes.decrypt(data, key, iv)
    local err, ret = caes.decrypt(data, key, iv)
    if err == 0 then
        return ret
    else
        error(string.format("aes decrypt error:%s", ret))
    end
end

function aes.encrypt(data, key, iv)
    local err, ret = caes.encrypt(data, key, iv)
    if err == 0 then
        return ret
    else
        error(string.format("aes decrypt error:%s", ret))
    end
end

return aes
