local md5 = require "md5"

local string_format = string.format
local string_upper  = string.upper
local table_sort    = table.sort
local table_concat  = table.concat

local M = {}
function M.md5_args(args)
    local list = {} 
    for k, v in pairs(args) do
        list[#list+1] = string_format("%s=%s", k, v)
    end
    assert(#list > 0, "need one arg at least")
    table_sort(list, function(a, b)
        return a < b
    end)
    local str = table_concat(list, "&")
    --print(str)
    return string_upper(md5.sumhexa(str))
end

return M
