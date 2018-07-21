local skynet        = require "skynet"
local socket        = require "skynet.socket"
local httpd         = require "http.httpd"
local sockethelper  = require "http.sockethelper"
local urllib        = require "http.url"
local json          = require "cjson"

local table = table
local string = string

local mode, module, port = ...
local CMD = require(module)

if mode == "agent" then
-- web 以json的格式发到服务器，服务器同样以json格式返回，每条请求都建立socket，都有返回结果
-- cmd为login时，验证密码，如果通过，返回token
-- cmd为其它任何命令，先验证token再进行操作
function on_message(cmd, data, body)
    if CMD[cmd] then
        return CMD[cmd](data, body)
    else
        return "cmd not exist"
    end
end

local function response(id, ...)
    local ok, err = httpd.write_response(sockethelper.writefunc(id), ...)
    if not ok then
        -- if err == sockethelper.socket_error , that means socket closed.
        skynet.error(string.format("fd = %d, %s", id, err))
    end
end

skynet.start(function()
    skynet.dispatch("lua", function (_,_,id)
        socket.start(id)
        -- limit request body size to 8192 (you can pass nil to unlimit)
        local code, url, method, header, body = httpd.read_request(sockethelper.readfunc(id), 8192)
        if code then
            if code ~= 200 then
                response(id, code)
            else
                local data 
                local path, query = urllib.parse(url)
                local cmd = string.match(path, "(%w+)$")        
                if query then
                    data = urllib.parse_query(query)
                end

                response(id, code, on_message(cmd, data, body), {["Access-Control-Allow-Origin"] = "*"})
            end
        else
            if url == sockethelper.socket_error then
                skynet.error("socket closed")
            else
                skynet.error(url)
            end
        end
        socket.close(id)
    end)
end)

elseif mode == "gate" then

skynet.start(function()
    local agent = {}
    for i= 1, 2 do
        agent[i] = skynet.newservice(SERVICE_NAME, "agent", module, port)
    end
    local balance = 1
    
    local id = socket.listen("0.0.0.0", port)
    socket.start(id , function(id, addr)
        --skynet.error(string.format("%s connected, pass it to agent :%08x", addr, agent[balance]))
        skynet.send(agent[balance], "lua", id)
        balance = balance + 1
        if balance > #agent then
            balance = 1
        end
    end)
end)

else
    assert(false, "mode error")
end
