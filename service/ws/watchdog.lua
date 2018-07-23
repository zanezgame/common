local skynet        = require "skynet"
local socket        = require "skynet.socket"
local websocket     = require "ws.socket"
local httpd         = require "http.httpd"
local urllib        = require "http.url"
local sockethelper  = require "http.sockethelper"
local json          = require "cjson"
local util          = require "util"

local player, port = ...
local NORET = "NORET"
local socks = {} -- id:ws

local function handle_socket(id)
    -- limit request body size to 8192 (you can pass nil to unlimit)
    local code, url, method, header, body = httpd.read_request(sockethelper.readfunc(id), 8192)
    if code then
        local agent = skynet.newservice("ws/agent", id, player, skynet.self())
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
            socks[id] = ws
            ws:start()
        end
    end
end

local CMD = {}
function CMD.send(id, msg)
    local ws = socks[id]
    assert(ws)
    ws:send_text(json.encode(msg))
end

skynet.start(function()
    local address = "0.0.0.0:"..port
    skynet.error("Listening "..address)
    local id = assert(socket.listen(address))
    socket.start(id , function(id, addr)
       socket.start(id)
       pcall(handle_socket, id)
    end)

    skynet.dispatch("lua", function(_, _, cmd1, ...)
        local ret = NORET
        local f = CMD[cmd1]
        if f then
            ret = f(...)
        end
        if ret ~= NORET then
            skynet.ret(skynet.pack(ret))
        end
    end)
end)
