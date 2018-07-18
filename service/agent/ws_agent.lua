local skynet = require "skynet"
local websocket = require "websocket"
local json = require "cjson"
local util = require "util"

local sock_id, player = ...
local player = require(player)

local NORET = "NORET"

local CMD = {}
function CMD.on_open()

end

function CMD.on_message(message)
    print("message", message)
    local data = json.decode(message)
    local recv_id = data.id
    if recv_id == "HearBeatPing" then
        -- todo change name
        return message
    end
    local resp_id = "S2c"..string.match(recv_id, "C2s(.+)")
    assert(player[recv_id], "net handler nil")
    if player[recv_id] then
        local msg = player[recv_id](player, data) or {}
        return json.encode({
            id = recv_id,
            msg = msg,
        })
    end
end

function CMD.on_close()

end

skynet.start(function()
    skynet.dispatch("lua", function(_, _, cmd1, cmd2, ...)
        local ret = NORET
        local f = CMD[cmd1]
        if f then
            ret = f(cmd2, ...)
        elseif player[cmd1] then
            local module = player[cmd1]
            if type(module) == "function" then
                ret = module(player, cmd2, ...)
            else
                ret = module[cmd2](module, ...)
            end
        end
        if ret ~= NORET then
            skynet.ret(skynet.pack(ret))
        end
    end)
end)

--[[
local function handle_socket(id)
    -- limit request body size to 8192 (you can pass nil to unlimit)
    local code, url, method, header, body = httpd.read_request(sockethelper.readfunc(id), 8192)
    if code then
        if header.upgrade == "websocket" then
            print("&&&&& new sock")
            --local agent = skynet.newservice("agent/ws_agent", id, player)
            local handler = {}
            function handler.on_open(ws)
                print(string.format("%d::open", ws.id))
                skynet.call(agent, "lua", "on_open") 
            end

            function handler.on_message(ws, message)
                print(string.format("%d receive:%s", ws.id, message))
                local ret = skynet.call(agent, "lua", "on_message") 
                ws:send_text(ret) 
            end

            function handler.on_close(ws, code, reason)
                print(string.format("%d close:%s  %s", ws.id, code, reason))
                skynet.call(agent, "lua", "on_close") 
                ws:close()
            end

            local ws = websocket.new(id, header, handler)
            ws:start()
        end
    end

end
]]
