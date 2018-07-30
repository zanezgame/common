local skynet    = require "skynet"
local socket    = require "skynet.socket"
local packet    = require "sock.packet"
local util      = require "util"
local opcode    = require "def.opcode"

local player    = ...
player          = require(player)

local FD
local WATCHDOG
local GATE
local protobuf -- 需要在节点启动时初始化 util.init_proto_env()
local _csn = 0
local _ssn = 0
local _crypt_type = 0
local _crypt_key = 0

local CMD = {}

local function send_package(op, tbl) 
    _ssn = _ssn + 1
    local data, len
    protobuf.encode(opcode.toname(op), tbl, function(buffer, bufferlen)
        data, len = packet.pack(op, _csn, _ssn, 
            _crypt_type, _crypt_key, buffer, bufferlen)
    end)
	socket.write(FD, data, len + 2)

end

skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
	unpack = function (buff, sz)
		return packet.unpack(buff, sz)
	end,
	dispatch = function (fd, _, op, csn, ssn, crypt_type, crypt_key, buff, sz)
		assert(fd == FD)	-- You can use fd to reply message
		skynet.ignoreret()	-- session is fd, don't call skynet.ret
        
        _csn = csn

        local opname = opcode.toname(op)
        local modulename = opcode.tomodule(op)
        local simplename = opcode.tosimplename(op)
        if opcode.has_session(op) then
            skynet.error("recv package, 0x%x %s, csn:%d", op, opname, csn)
        end

        local data = protobuf.decode(opname, buff, sz)
        assert(type(data) == "table", data)
        util.printdump(data)

        send_package(op+1, {err = 88})
	end
}

function CMD.start(conf)
	FD = conf.fd
	GATE = conf.gate
    WATCHDOG = conf.WATCHDOG

	skynet.call(GATE, "lua", "forward", FD)
end

function CMD.disconnect()
	-- todo: do something before exit
	skynet.exit()
end

skynet.start(function()
	skynet.dispatch("lua", function(_,_, command, ...)
		local f = assert(CMD[command])
		util.ret(f(...))
	end)
    protobuf = util.get_protobuf()
end)
