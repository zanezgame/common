local skynet        = require "skynet"
local socket        = require "skynet.socket"
local httpd         = require "http.httpd"
local sockethelper  = require "http.sockethelper"
local urllib        = require "http.url"
local json          = require "cjson"
local util          = require "util"

local table = table
local string = string

local mode, server_path, player_path, port, preload, gate = ...
local port = tonumber(port)
local preload = preload and tonumber(preload) or 20

if mode == "agent" then
local player = require(player_path)

-- 如果是非字符串，player需要提供pack和unpack方法
player.pack = player.pack or function (_, data)
    return data
end
player.unpack = player.unpack or function (_, data)
    return data
end

function on_message(cmd, data, body, ip)
    if player[cmd] then
        local ret = player[cmd](player, player:unpack(data), ip)
        return player:pack(ret or "")
    else
        return '{"err":-1}'
    end
end

local function response(fd, ...)
    local ok, err = httpd.write_response(sockethelper.writefunc(fd), ...)
    if not ok then
        -- if err == sockethelper.socket_error , that means socket closed.
        skynet.error(string.format("fd = %d, %s", fd, err))
    end
end

skynet.start(function()
    skynet.dispatch("lua", function (_,_,fd, ip)
        socket.start(fd)
        -- limit request body size to 8192 (you can pass nil to unlimit)
        local code, url, method, header, body = httpd.read_request(sockethelper.readfunc(fd), 8192)
        --print(string.format("recv code:%s, url:%s, method:%s, header:%s, body:%s", code, url, method, header, body))
        if code then
            if code ~= 200 then
                response(fd, code)
            else
                local data 
                local path, query = urllib.parse(url)
                local cmd = string.match(path, "([^/]+)$")        
                if query then
                    data = urllib.parse_query(query)
                end

                response(fd, code, on_message(cmd, data, body, ip), {["Access-Control-Allow-Origin"] = "*"})
            end
        else
            if url == sockethelper.socket_error then
                skynet.error("socket closed")
            else
                skynet.error(url)
            end
        end
        socket.close(fd)
    end)
    player:init(gate)
end)

elseif mode == "gate" then

local server 
if server_path then
    server = require(server_path) 
end

skynet.start(function()
    if server then
        server:start()
    end

    local agent = {}
    for i= 1, preload do
        agent[i] = skynet.newservice(SERVICE_NAME, "agent", server_path, player_path, port, preload, skynet.self())
    end
    local balance = 1
    
    local fd = socket.listen("0.0.0.0", port)
    socket.start(fd , function(fd, ip)
        --skynet.error(string.format("%s connected, pass it to agent :%08x", addr, agent[balance]))
        skynet.send(agent[balance], "lua", fd, ip)
        balance = balance + 1
        if balance > #agent then
            balance = 1
        end
    end)

    skynet.dispatch("lua", function(_, _, cmd, subcmd, ...)
        local f = assert(server[cmd], cmd)
        if type(f) == "function" then
            util.ret(f(server, subcmd, ...))
        else
            util.ret(f[subcmd](f, ...))
        end
    end)
end)

else
    assert(false, "mode error")
end
