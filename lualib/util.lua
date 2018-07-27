local skynet = require "skynet"
local LOG = skynet.error

local util = {}
-- 处理skynet.send的消息
util.NORET = "NORET"
function util.ret(noret, ...)
    if noret ~= "NORET" then
        skynet.ret(skynet.pack(noret, ...))
    end
end

-- 有需要的节点在启动时调用
function util.env_protobuf(path)
    debug.getregistry().PROTOBUF_ENV = protobuf_c._env_new()
    local protobuf = require "protobuf"
    protobuf.register_file(path)
end


function util.to_version_num(version)
    local v1, v2, v3 = string.match(version, "(%d+)%.(%d+)%.(%d+)")
	if not v1 then
        return
    end
	return v1*1000000 + v2*1000 + v3
end

function util.to_version_str(num)
    return string.format("%d.%d.%d", num//1000000, num%1000000//1000, num%1000) 
end

function util.shell(cmd, ...)
    local cmd = string.format(cmd, ...)
    LOG(cmd)
    return io.popen(cmd):read("*all")
end

function util.run_cluster(clustername)
    local config = require "config"
    local cmd = string.format("cd %s/shell && sh start.sh %s", config.workspace, clustername)
    LOG(cmd)
    os.execute(cmd)
end

function util.trace(prefix, ...)
    local config = require "config"
    if config.debug then
        prefix = "["..prefix.."] "
        return function(...)
            LOG(prefix .. string.format(...))
        end
    else
        return function() end
    end
end

function util.gc()
    local config = require "config"
    if config.debug then
        collectgarbage("collect")
        return collectgarbage("count")
    end
end

-- 字符串分割
function util.split(s, delimiter, t)
    assert(string.len(delimiter) == 1)

    local arr = {}
    local idx = 1

    for value in string.gmatch(s, "[^" .. delimiter .. "]+") do
        if t == "number" then
            value = tonumber(value)
        end
        arr[idx] = value
        idx = idx + 1
    end

    return arr
end

function util.dump(root, ...)
    local tbl = {}
    local filter = {[root] = tostring(root)}
    for _, v in ipairs({...}) do
        filter[v] = tostring(v)
    end
    local function _to_key(k)
        if tonumber(k) then
            return '[' .. k .. ']'
        else
            return '["' .. k .. '"]'
        end
    end
    local function _dump(t, name, space)
        space = space .. "  "
        for k, v in pairs(t) do
            if filter[v] then

                table.insert(tbl, space .. _to_key(k) .. " = " .. filter[v])
            elseif filter[v] or type(v) ~= "table" then
                local val = tostring(v)
                if type(v) == "string" then
                    val = '"' .. tostring(v) .. '"'
                end
                table.insert(tbl, space .. _to_key(k) .. " = " .. val ..",")
            else
                filter[v] = name .. "." .. _to_key(k)
                table.insert(tbl, space .. _to_key(k) .. " = {")
                _dump(v, name .. "." .. _to_key(k),  space)
                table.insert(tbl, space .. "},")
            end
        end
    end

    table.insert(tbl, "{")
    _dump(root, "", "")
    table.insert(tbl, "}")

    return table.concat(tbl, "\n")
end

function util.printdump(root, ...)
    LOG(util.dump(root, ...))
end

function util.is_in_list(list, obj)
    for _, o in pairs(list) do
        if o == obj then
            return true
        end
    end
    return false
end

-- 把table中类型为string的数字key转换成number
function util.key_string_to_number(tbl)
    if type(tbl) ~= "table" then return tbl end
    local data = {}
    for k,v in pairs(tbl) do
        k = tonumber(k) or k
        v = type(v) == "table" and util.key_string_to_number(v) or v
        data[k] = v
    end
    return data 
end

function util.key_number_to_string(tbl)
    if type(tbl) ~= "table" then return tbl end
    local data = {}
    for k,v in pairs(tbl) do
        k = tostring(k)
        v = type(v) == "table" and util.key_number_to_string(v) or v
        data[k] = v
    end
    return data 
end


function new_module(modname)
    skynet.cache.clear()
    local module = package.loaded[modname]
    if module then
        package.loaded[modname] = nil
    end
    local new_module = require(modname) 
    package.loaded[modname] = module
    return new_module
end

local class_prop = {
    classname = true,
    class = true,
    Get = true,
    Set = true,
    super = true,
    __newindex = true,
    __index = true,
    new = true,
}

function util.reload_class(modname)
    local old_class = require(modname)
    local new_class = new_module(modname)

    if old_class.classname and old_class.class then
        for k, v in pairs(new_class.class) do
            if not class_prop[k] then
                old_class[k] = v
            end
        end
    else
        for k, v in pairs(new_class) do
            old_class[k] = v
        end
    end
end

function util.reload_module(modname)
    if not package.loaded[modname] then
        require(modname)
        return require(modname)
    end
    local old_module = require(modname)
    local new_module = new_module(modname)

    for k,v in pairs(new_module) do
        if type(k) == "function" then
            old_class[k] = v
        end
    end
    return old_module
end

function util.clone(obj, deep)
    local lookup = {}
    local function _clone(obj, deep)
        if type(obj) ~= "table" then
            return obj
        elseif lookup[obj] then
            return lookup[obj]
        end

        local new = {}
        lookup[obj] = new
        for key, value in pairs(obj) do
            if deep then
                new[_clone(key, deep)] = _clone(value, deep)
            else
                new[key] = value
            end
        end

        return setmetatable(new, getmetatable(obj))
    end

    return _clone(obj, deep)
end

function util.short_name(name)
    return string.match(name, "_(%S+)") or name
end

function util.merge_list(list1, list2)
    local list = {}
    for _, v in ipairs(list1) do
        table.insert(list, v)
    end
    for _, v in ipairs(list1) do
        table.insert(list, v)
    end
    return list
end

local function tostring_ex(value)
    if type(value)=='table' then
        return util.tbl2str(value)
    elseif type(value)=='string' then
        return "\'"..value.."\'"
    else
        return tostring(value)
    end
end

function util.tbl2str(t)
    if t == nil then return "" end
    local retstr= "{"

    local i = 1
    for key,value in pairs(t) do
        local signal = ","
        if i==1 then
            signal = ""
        end

        if key == i then
            retstr = retstr..signal..tostring_ex(value)
        else
            if type(key)=='number' or type(key) == 'string' then
                retstr = retstr..signal..'['..tostring_ex(key).."]="..tostring_ex(value)
            else
                if type(key)=='userdata' then
                    retstr = retstr..signal.."*s"..util.tbl2str(getmetatable(key)).."*e".."="..tostring_ex(value)
                else
                    retstr = retstr..signal..key.."="..tostring_ex(value)
                end
            end
        end

        i = i+1
    end

    retstr = retstr.."}"
    return retstr
end

function util.str2tbl(str)
    if str == nil or type(str) ~= "string" then
        return
    end
    return load("return " .. str)()
end

-- 方法本身
function util.callee()
    return debug.getinfo(2, "f").func
end

return util
