-- 一个虚拟机只能有一个
local skynet = require "skynet"
local socket = require "skynet.socket"
local packet = require "packet"

local fd

local M = {}
function M.start(host, port)
    fd = socket.open(host, port)
    assert(fd)

    skynet.fork(function()
        while true do
            local ret = socket.read(fd)
            print("recv &&&&", ret)
            skynet.sleep(100)
        end
    end)
end

function M.pack(str)

end

function M.unpack(buff)

end

function M.send(data)
    data = string.pack(">s2", data)
    socket.write(fd, data) 
end

function M.call()

end

function M.test(func)
    
end

return M
