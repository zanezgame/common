local skynet = require "skynet.manager"
local cluster = require "skynet.cluster"
local c_name = require "stop_conf"
local conf = require "conf"
local util = require "util"

skynet.start(function()
    cluster.reload(conf.clustername)
    cluster.open "stop"
    cluster.call(c_name, "svr", "stop")
    skynet.abort()
end)
