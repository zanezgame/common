local skynet = require "skynet"
local websocket = require "websocket"
local json = require "cjson"

local sock_id, header, player = ...
local player = require(player)

local handler = {}
function handler.on_open(ws)
    print(string.format("%d::open", ws.id))
end

function handler.on_message(ws, message)
    print(string.format("%d receive:%s", ws.id, message))
    local data = json.decode(message)
    local recv_id = data.id
    local resp_id = "C2s"..string.match(recv_id, "C2s(.+)")
    assert(player[recv_id], "net handler nil")
    if player[recv_id] then
        local msg = player[recv_id](player, data) or {}
        ws:send_text({
            id = recv_id,
            msg = json.encode(msg),
        })
    end
end

function handler.on_close(ws, code, reason)
    print(string.format("%d close:%s  %s", ws.id, code, reason))
    ws:close()
end

skynet.start(function()
    local ws = websocket.new(id, header, handler)
    ws:start()   
end)

