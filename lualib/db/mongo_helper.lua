local skynet    = require "skynet"
local mongo     = require "skynet.db.mongo"
local bson      = require "bson"
local util      = require "util"

local host, port, db_name
local db

local function collection(name)
    db = db or mongo.client({host = host, port = port})
    return db[db_name][name]
end

local function get_global_data(key)
    local col = collection("base")
    local tbl = col:findOne({table_name = "global"})
    return util.key_string_to_number(tbl[key])
end

local function save_global_data(key, value)
    local col = collection("base")
    local update_doc = {}
    update_doc[key] = util.key_number_to_string(value)
    return col:findAndModify({query = {table_name = "global"}, update = {["$set"] = update_doc}})
end

local M = {}
function M.connect(_host, _port, _db_name)
    host = _host
    port = _port
    db_name = _db_name
end

function M.disconnect()
    if db then
        db:disconnect() 
        db = nil
    end
end

function M.find_one(collect_name, query, selector)
    local data = collection(collect_name):findOne(query, selector)
    return util.key_string_to_number(data)
end

function M.find_one_with_default(collect_name, query, default, selector)
    local data = collection(collect_name):findOne(query, selector)
    if not data then
        M.insert(collect_name, default)
        return default
    end
    return util.key_string_to_number(data)
end

function M.find(collect_name, query, selector)
    local ret = collection(collect_name):find(query, selector)
    local data = {}
    while ret:hasNext() do
        table.insert(data, ret:next())
    end
    return util.key_string_to_number(data)
end

function M.update(collect_name, query_tbl, update_tbl)
    update_tbl = util.key_number_to_string(update_tbl)
    local col = collection(collect_name)
    return col:findAndModify({query = query_tbl, update = update_tbl})
end

function M.insert(collect_name, tbl)
    tbl = util.key_number_to_string(tbl)
    local col = collection(collect_name)
    return col:safe_insert(tbl)
end

function M.delete(collect_name, query_tbl)
    local col = collection(collect_name)
    return col:delete(query_tbl) 
end

function M.drop(collection_name)
    return db[db_name][collection_name]:drop()
end

function M.query_player(account, default_player)
    local col = collection("player") 
    local ret = col:findOne({account = account})
    if not ret and default_player then
        col:safe_insert(default_player)
        ret = col:findOne({account = account})
    end
    return util.key_string_to_number(ret)
end

function M.save_player(account, data)
    data = util.key_number_to_string(data)
    local col = collection("player")
    return col:findAndModify({query = {account = account}, update = data})
end

function M.auto_id()
    local auto_id = get_global_data("auto_id") or 0
    auto_id = auto_id + 1
    save_global_data("auto_id", auto_id)
    return auto_id
end

function M.get_global_data(key)
    return get_global_data(key)
end

function M.save_global_data(key, value)
    save_global_data(key, value)
end

return M
