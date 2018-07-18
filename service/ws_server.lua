local skynet = require "skynet"
local socket = require "skynet.socket"
local websocket = require "websocket"
local httpd = require "http.httpd"
local urllib = require "http.url"
local sockethelper = require "http.sockethelper"

local player, port = ...

local function handle_socket(id)
    -- limit request body size to 8192 (you can pass nil to unlimit)
    local code, url, method, header, body = httpd.read_request(sockethelper.readfunc(id), 8192)
    if code then
        local agent = skynet.newservice("agent/ws_agent", id, player)
        local handler = {}
        function handler.on_open(ws)
            print(string.format("%d::open", ws.id))
            skynet.call(agent, "lua", "on_open") 
        end

        function handler.on_message(ws, message)
            print(string.format("%d receive:%s", ws.id, message))
            local ret = skynet.call(agent, "lua", "on_message", message) 
        end

        function handler.on_close(ws, code, reason)
            print(string.format("%d close:%s  %s", ws.id, code, reason))
            skynet.call(agent, "lua", "on_close") 
            ws:close()
        end

        if header.upgrade == "websocket" then
            local ws = websocket.new(id, header, handler)
            ws:start()
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
