local skynet    = require "skynet"
local util      = require "util"

local room_path = ...
local room_t = require(room_path)

local rooms = {}
local function create_room(room_id)
   local room = room_t.new(room_id, function()
        rooms[room_id] = nil  
   end)
   rooms[room_id] = room
   return room
end

skynet.start(function()
    skynet.dispatch("lua", function(_, _, room_id, cmd, ...)
        local room = rooms[room_id] or create_room(room_id)
        local f = assert(room[cmd], cmd)
        util.ret(f(room, ...))
    end)
end)

