-- 一个虚拟机只能有一个
local skynet = require "skynet"
local socket = require "skynet.socket"
local packet = require "packet"

local fd

local M = {}
local mt = {__index = M}
function M.new(...)
    local t = {}
    M.ctor(t, ...)
    return setmetatable(t, mt)
end

function M:ctor(host, port)
    self.host = host
    self.port = port
    self.fd = nil
    self.csn = 0 -- client session
    self.ssn = 0 -- server session
    self.crypt_type = 0
    self.crypt_key = 0
end

function M:start()
    self.fd = socket.open(self.host, self.port)
    assert(self.fd)

    skynet.fork(function()
        while true do
            local buff, sz = socket.read(self.fd)
            print("recv &&&&", buff, sz)
            skynet.sleep(100)
        end
    end)
end

function M:recv_package(buff, sz)

end

function M:send(op, data)
    self.csn = self.csn + 1
    local buff, sz = packet.pack(op, self.csn, self.ssn, 
        self.crypt_type, self.crypt_key, data, #data)
    print("send", buff, sz)
    socket.write(self.fd, buff, sz+2)
    --socket.write(self.fd, string.pack(">s2", data) )
end

function M:call()

end

function M:test(func)
    
end

return M
