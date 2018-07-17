local skynet = require "skynet"
local socket = require "skynet.socket"
local httpd = require "http.httpd"
local urllib = require "http.url"
local sockethelper = require "http.sockethelper"
local util = require "util"

local player, port = ...



local function handle_socket(id)
    -- limit request body size to 8192 (you can pass nil to unlimit)
    local code, url, method, header, body = httpd.read_request(sockethelper.readfunc(id), 8192)
    if code then
        if header.upgrade == "websocket" then
            skynet.newservice("agent/ws_agent", id, "fuck", player)
        end
    end

end

skynet.start(function()
    local address = "0.0.0.0:"..port
    skynet.error("Listening "..address)
    local id = assert(socket.listen(address))
    socket.start(id , function(id, addr)
       socket.start(id)
       pcall(handle_socket, id)
    end)
end)
