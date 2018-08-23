local db = require "db.redis_helper"

local M = {}
function M.add(ip)
    db.sadd("blacklist", ip)
end

function M.remove(ip)
    db.srem("blacklist", ip)
end

function M.check(ip)
    return db.sismember("blacklist", ip)
end

function M.list()
    return db.smembers("blacklist")
end

function M.import(filepath)
    local file = io.open(filepath, "r")
    while true do
        local ip = file:read()
        if not ip then
            break
        end
        M.add(ip)
    end
    file:close()
end

function M.export(filepath)
    local list = M.list()
    local file = io.open(filepath, "w+")
    for _, ip in ipairs(list) do
        file:write(ip.."\n")
    end
    file:close()
end

function M.clear()
    return db.del "blacklist"
end

return M
