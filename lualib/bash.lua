local skynet = require "skynet"
package.path = "?.lua;" .. package.path
OS = io.popen('uname'):read("*l")
OS = (OS == 'Darwin') and 'osx' or (OS == 'Linux' and 'linux' or 'win32')

function add_lua_search_path(path)
    if not string.find(package.path, path, 1, true) then
        print("add search path: " .. path)
        package.path = path .. "/?.lua;" .. package.path
    end
end

function command(cmd, ...)
    local file = io.popen(string.format(cmd, ...))
    local data = file:read("*a")
    file:close()
    return string.match(data, "(.*)[\n\r]+$") or data
end

function execute(cmd, ...)
    local cmd = string.format(cmd, ...)
    os.execute(cmd)
end

function realpath(path)
    if not (OS == 'osx' or OS == 'linux') then
        if path == '`pwd`' then
            return '.'
        else
            return path
        end
    else
        local file = io.popen('realpath ' .. path)
        local data = file:read("*l")
        file:close()
        return data
    end
end

function cat(path)
    local file = io.open(path)
    assert(file, "file not found: " .. path)
    local data = file:read("*a")
    file:close()
    return data
end

function exist(path)
    local file = io.open(path)
    if file then
        file:close()
    end
    return file ~= nil
end

function wcat(path)
    local file = io.popen("lynx -source " .. path)
    local data = file:read("*a")
    file:close()
    return data
end

function echo(path, content)
    local file = io.open(path, "w")
    file:write(content)
    file:flush()
    file:close()
end

local function lookup_local(level, key)
    assert(key and #key > 0, key)
    for i = 1, 256 do
        local k, v = debug.getlocal(level, i)
        if k == key then
            return v
        elseif not k then
            break
        end
    end

    local info1 = debug.getinfo(level, 'S')
    local info2 = debug.getinfo(level + 1, 'S')
    if info1.source == info2.source or
        info1.short_src == info2.short_src then
        return lookup_local(level + 1, key)
    end
end

function bash(expr, ...)
    if select('#', ...) > 0 then
        expr = string.format(expr, ...)
    end
    local function eval(expr)
        return string.gsub(expr, "(${?[%w_]+}?)", function (str)
            local key = string.match(str, "[%w_]+")
            local value = lookup_local(6, key) or _G[key]
            if value == nil then
                error("value not found for " .. key)
            else
                return tostring(value)
            end
        end)
    end
    local cmd = eval(expr)
    --skynet.error(cmd)
    local ret = io.popen(cmd):read("*a")
    if ret ~= "" then
        --skynet.error(ret)
    end
    return ret
end

function remote_bash(user, host, expr, ...)
    local cmd = string.format(expr, ...)
    if host == "localhost" or host == "127.0.0.1" then
        return bash(cmd)
    end
    return bash('ssh %s@%s "%s"', user, host, cmd)
end

