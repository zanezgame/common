local skynet = require "skynet"
local socket = require "client.socket"

local ws
local url = ...

local CMD = {}
function CMD.connect(url)
    local id = socket.connect("118.126.99.239", 8002)
    print("socket id", id)
end

skynet.start(function()		
    CMD.connect(url)  
end)
