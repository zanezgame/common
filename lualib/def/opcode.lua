-- 协议号规范
-- 0x0000 ~ 0x00ff 客户端自已给自己发
-- 0x0100 ~ 0x0fff 服务器给客户端发
-- 0x1000 ~ 0x4fff 与游戏服之间的rpc
-- 0x5000 ~ 0x9fff 与国战服之间的rpc
-- 0xa000 ~ 0xbfff 与登陆服之间的rpc
-- 0xb000 ~ 0xcfff 玩家离线操作

error("请在项目目录下创建/script/def/opcode.lua")

local opcode = {}
local code2name = {}
local code2module = {}
local code2simplename = {}
local code2no_session = {}
local code2urlrequest = {}

local NOSESSION = true
local function REG(code, message_name, urlrequest, no_session)
    assert(not code2name[code], string.format("code 0x%x exist", code))

    local namespace = opcode
    for v in string.gmatch(message_name, "([^.]+)[.]") do
        namespace[v] = rawget(namespace, v) or setmetatable({}, {
            __index = function(_, k) error(k) end})
        namespace = namespace[v]
    end

    namespace[string.match(message_name, "[%w_]+$")] = code
    code2name[code] = message_name
    code2urlrequest[code] = urlrequest
    code2no_session[code] = no_session 
    code2module[code] = string.match(message_name, "^[^.]+")
    code2simplename[code] = string.match(message_name, "[^.]+$")
end

function opcode.toname(code)
    return code2name[code]
end

function opcode.tomodule(code)
    return code2module[code]
end

function opcode.tosimplename(code)
    return code2simplename[code]
end

function opcode.has_session(code)
    return not code2no_session[code]
end

function opcode.urlrequest(code)
    return code2urlrequest[code]
end

--
-- connection
--
REG(0x00F1, "connection.connected")
REG(0x00F3, "connection.disconnected")
REG(0x00F5, "connection.ioerror")

----------------------------------------------------------------
-- S2C 服务器主动发给客户端的封包    
REG(0x0111, "user.s2c_log", false, NOSESSION)
REG(0x0113, "user.s2c_text", false, NOSESSION)
REG(0x0115, "user.s2c_level_up")
REG(0x0117, "user.s2c_sync")
REG(0x0121, "count.s2c_sync")
REG(0x0141, "cdtime.s2c_sync", false, NOSESSION)
REG(0x0151, "hero.s2c_invite")
REG(0x0153, "hero.s2c_update_hero")
REG(0x0155, "hero.s2c_update_value")
REG(0x0171, "bag.s2c_sync_item")
REG(0x0172, "bag.s2c_remove_item")
REG(0x0181, "chat.s2c_msg", false, NOSESSION)
REG(0x01a1, "quest.s2c_sync")
REG(0x01b1, "dayquest.s2c_sync")
REG(0x01c1, "instance.s2c_sync")
REG(0x01e1, "war.s2c_result")
REG(0x01e2, "war.s2c_join_war")
REG(0x01f1, "achieve.s2c_sync")
    
     
----------------------------------------------------------------
-- RPC 客户端请求的RPC封包，必须成对 ，服务端协议号加1
REG(0xa000, "login.c2s_check_account", false, RETURNERR)
REG(0xa001, "login.s2c_check_account", false, RETURNERR)
REG(0xa002, "login.c2s_register", false, RETURNERR)
REG(0xa003, "login.s2c_register", false, RETURNERR)

   
----------------------------------------------------------------
-- RPC 客户端请求的RPC封包，必须成对 ，服务端协议号加1
-- ping 
REG(0x1000, "ping.c2s_ping", false, NOSESSION)
REG(0x1001, "ping.s2c_ping", false, NOSESSION)

-- login
REG(0x1010, "login.c2s_login")
REG(0x1011, "login.s2c_login")
REG(0x1012, "login.c2s_reconnect")
REG(0x1013, "login.s2c_reconnect")

-- user
REG(0x1020, "user.c2s_data")
REG(0x1021, "user.s2c_data")
REG(0x1022, "user.c2s_set_avatar")
REG(0x1023, "user.s2c_set_avatar")
REG(0x1024, "user.c2s_set_player_name")
REG(0x1025, "user.s2c_set_player_name")
REG(0x1028, "user.c2s_buy_silver")
REG(0x1029, "user.s2c_buy_silver")
REG(0x102a, "user.c2s_random_player_name")
REG(0x102b, "user.s2c_random_player_name")
REG(0x102c, "user.c2s_create_role")
REG(0x102d, "user.s2c_create_role")

-- cdtime
REG(0x1040, "cdtime.c2s_data")
REG(0x1041, "cdtime.s2c_data")

-- gm
REG(0x1050, "gm.c2s_gmcmd")
REG(0x1051, "gm.s2c_gmcmd")

-- count 
REG(0x1060, "count.c2s_data")
REG(0x1061, "count.s2c_data")

-- hero  
REG(0x1100, "hero.c2s_data")
REG(0x1101, "hero.s2c_data")
REG(0x1102, "hero.c2s_invite_by_soul")
REG(0x1103, "hero.s2c_invite_by_soul")
REG(0x1104, "hero.c2s_upgrade")
REG(0x1105, "hero.s2c_upgrade")
REG(0x1108, "hero.c2s_up_star")
REG(0x1109, "hero.s2c_up_star")
REG(0x110c, "hero.c2s_equip_item")
REG(0x110d, "hero.s2c_equip_item")
REG(0x110e, "hero.c2s_unequip_item")
REG(0x110f, "hero.s2c_unequip_item")
REG(0x1120, "hero.c2s_set_soldier")
REG(0x1121, "hero.s2c_set_soldier")
REG(0x1122, "hero.c2s_upgrade_soldier")
REG(0x1123, "hero.s2c_upgrade_soldier")
REG(0x1124, "hero.c2s_upgrade_skill")
REG(0x1125, "hero.s2c_upgrade_skill")
REG(0x1126, "hero.c2s_reset_skill")
REG(0x1127, "hero.s2c_reset_skill")
REG(0x1128, "hero.c2s_set_formation")
REG(0x1129, "hero.s2c_set_formation")

-- bag 
REG(0x1200, "bag.c2s_data")
REG(0x1201, "bag.s2c_data")
REG(0x1202, "bag.c2s_sell")
REG(0x1203, "bag.s2c_sell")
REG(0x1204, "bag.c2s_build")
REG(0x1205, "bag.s2c_build")
REG(0x1206, "bag.c2s_use_item")
REG(0x1207, "bag.s2c_use_item")
REG(0x1208, "bag.c2s_strength_equip")
REG(0x1209, "bag.s2c_strength_equip")
REG(0x120a, "bag.c2s_detach_equip")
REG(0x120b, "bag.s2c_detach_equip")
REG(0x120c, "bag.c2s_open_gift")
REG(0x120d, "bag.s2c_open_gift")

-- invite
REG(0x1300, "invite.c2s_invite_one")
REG(0x1301, "invite.s2c_invite_one")
REG(0x1302, "invite.c2s_invite_ten")
REG(0x1303, "invite.s2c_invite_ten")

-- rank
REG(0x1400, "rank.c2s_data")
REG(0x1401, "rank.s2c_data")

-- shop
REG(0x1500, "shop.c2s_data")
REG(0x1501, "shop.s2c_data")
REG(0x1502, "shop.c2s_refresh")
REG(0x1503, "shop.s2c_refresh")
REG(0x1504, "shop.c2s_buy")
REG(0x1505, "shop.s2c_buy")
REG(0x1506, "shop.c2s_clear_cd")
REG(0x1507, "shop.s2c_clear_cd")

-- chat     
REG(0x1600, "chat.c2s_send", false, NOSESSION)
REG(0x1601, "chat.s2c_send", false, NOSESSION)

-- mail 
REG(0x1700, "mail.c2s_data")
REG(0x1701, "mail.s2c_data")
REG(0x1702, "mail.c2s_pull_item")
REG(0x1703, "mail.s2c_pull_item")
REG(0x1704, "mail.c2s_delete_one")
REG(0x1705, "mail.s2c_delete_one")
REG(0x1706, "mail.c2s_delete_all")
REG(0x1707, "mail.s2c_delete_all")
REG(0x1708, "mail.c2s_read_one")
REG(0x1709, "mail.s2c_read_one")
REG(0x170a, "mail.c2s_read_all")
REG(0x170b, "mail.s2c_read_all")

-- checkin  
REG(0x1800, "checkin.c2s_data")
REG(0x1801, "checkin.s2c_data")
REG(0x1802, "checkin.c2s_checkin")
REG(0x1803, "checkin.s2c_checkin")

-- quest    
REG(0x1900, "quest.c2s_data")
REG(0x1901, "quest.s2c_data")
REG(0x1902, "quest.c2s_reward")
REG(0x1903, "quest.s2c_reward")

-- achieve
REG(0x1a00, "achieve.c2s_data")
REG(0x1a01, "achieve.s2c_data")
REG(0x1a02, "achieve.c2s_reward")
REG(0x1a03, "achieve.s2c_reward")

-- guide
REG(0x1f00, "guide.c2s_data")
REG(0x1f01, "guide.s2c_data")
REG(0x1f02, "guide.c2s_set")
REG(0x1f03, "guide.s2c_set")

-- activity
REG(0x2000, "activity.c2s_pass_instance")
REG(0x2001, "activity.s2c_pass_instance")
REG(0x2002, "activity.c2s_enter_instance")
REG(0x2003, "activity.s2c_enter_instance")

-- stratagem
REG(0x2200, "stratagem.c2s_develop")
REG(0x2201, "stratagem.s2c_develop")
REG(0x2202, "stratagem.c2s_clear_cd")
REG(0x2203, "stratagem.s2c_clear_cd")

-- pay
REG(0x2300, "pay.c2s_data")
REG(0x2301, "pay.s2c_data")
REG(0x2302, "pay.c2s_pay")
REG(0x2303, "pay.s2c_pay")
REG(0x2304, "pay.c2s_sum_reward")
REG(0x2305, "pay.s2c_sum_reward")
REG(0x2306, "pay.c2s_daily_reward")
REG(0x2307, "pay.s2c_daily_reward")
REG(0x2308, "pay.c2s_grow_reward")
REG(0x2309, "pay.s2c_grow_reward")
REG(0x230a, "pay.c2s_buy_grow")
REG(0x230b, "pay.s2c_buy_grow")
REG(0x230c, "pay.c2s_first_reward")
REG(0x230d, "pay.s2c_first_reward")

-- war
REG(0x2502, "war.c2s_server_info")
REG(0x2503, "war.s2c_server_info")
REG(0x2504, "war.c2s_read_result")
REG(0x2505, "war.s2c_read_result")

-- post
REG(0x2600, "post.c2s_data")
REG(0x2601, "post.s2c_data")
REG(0x2602, "post.c2s_buy_suit")
REG(0x2603, "post.s2c_buy_suit")
REG(0x2604, "post.c2s_pull_daily_reward")
REG(0x2605, "post.s2c_pull_daily_reward")
REG(0x2606, "post.c2s_pull_week_reward")
REG(0x2607, "post.s2c_pull_week_reward")
REG(0x2608, "post.c2s_pull_post_reward")
REG(0x2609, "post.s2c_pull_post_reward")

-- setting
REG(0x2700, "setting.c2s_data")
REG(0x2701, "setting.s2c_data")
REG(0x2702, "setting.c2s_set")
REG(0x2703, "setting.s2c_set")

-- system
REG(0x2800, "system.c2s_data")
REG(0x2801, "system.s2c_data")

-- team
REG(0x2900, "team.c2s_data")
REG(0x2901, "team.s2c_data")
REG(0x2902, "team.c2s_team_list")
REG(0x2903, "team.s2c_team_list")
REG(0x2904, "team.c2s_req_invite")
REG(0x2905, "team.s2c_req_invite")
REG(0x2906, "team.c2s_resp_invite")
REG(0x2907, "team.s2c_resp_invite")
REG(0x2908, "team.c2s_req_join")
REG(0x2909, "team.s2c_req_join")
REG(0x290a, "team.c2s_resp_join")
REG(0x290b, "team.s2c_resp_join")
REG(0x290c, "team.c2s_create")
REG(0x290d, "team.s2c_create")
REG(0x290e, "team.c2s_dismiss")
REG(0x290f, "team.s2c_dismiss")
REG(0x2910, "team.c2s_quit")
REG(0x2911, "team.s2c_quit")
REG(0x2912, "team.c2s_kick")
REG(0x2913, "team.s2c_kick")
REG(0x2914, "team.c2s_match")
REG(0x2915, "team.s2c_match")
REG(0x2916, "team.c2s_cancel_match")
REG(0x2917, "team.s2c_cancel_match")

-- friend
REG(0x2a00, "friend.c2s_data")
REG(0x2a01, "friend.s2c_data")


----------------------------------------------------------------
-- 国战服消息
REG(0x5000, "war.c2s_data")
REG(0x5001, "war.s2c_data")
REG(0x5002, "war.c2s_move_reserve")
REG(0x5003, "war.s2c_move_reserve")
REG(0x5004, "war.c2s_attack")
REG(0x5005, "war.s2c_attack")
REG(0x5008, "war.c2s_surrender")
REG(0x5009, "war.s2c_surrender")
REG(0x500a, "war.c2s_build_affairs")
REG(0x500b, "war.s2c_build_affairs")
REG(0x500c, "war.c2s_destroy_affairs")
REG(0x500d, "war.s2c_destroy_affairs")
REG(0x500e, "war.c2s_upgrade_affairs")
REG(0x500f, "war.s2c_upgrade_affairs")
REG(0x5010, "war.c2s_gm")
REG(0x5011, "war.s2c_gm")
REG(0x5012, "war.c2s_recover_hp")
REG(0x5013, "war.s2c_recover_hp")
REG(0x5014, "war.c2s_request_ally")
REG(0x5015, "war.s2c_request_ally")
REG(0x5016, "war.c2s_respone_ally")
REG(0x5017, "war.s2c_respone_ally")
REG(0x5018, "war.c2s_terminate_ally")
REG(0x5019, "war.s2c_terminate_ally")
REG(0x501a, "war.c2s_defend")
REG(0x501b, "war.s2c_defend")
REG(0x501c, "war.c2s_use_stratagem")
REG(0x501d, "war.s2c_use_stratagem")
REG(0x501e, "war.c2s_scout")
REG(0x501f, "war.s2c_scout")
REG(0x5020, "war.c2s_auto_soldier")
REG(0x5021, "war.s2c_auto_soldier")
REG(0x5022, "war.c2s_auto_upgrade")
REG(0x5023, "war.s2c_auto_upgrade")
REG(0x5024, "war.c2s_assist")
REG(0x5025, "war.s2c_assist")
REG(0x5026, "war.c2s_assist_cancel")
REG(0x5027, "war.s2c_assist_cancel")
REG(0x5028, "war.c2s_npc_attack")
REG(0x5029, "war.s2c_npc_attack")

REG(0x6000, "war.s2c_add_player")
REG(0x6001, "war.s2c_remove_player")
REG(0x6002, "war.s2c_sync_city")
REG(0x6003, "war.s2c_add_troop")
REG(0x6004, "war.s2c_remove_troop")
REG(0x6005, "war.s2c_sync_info")

----------------------------------------------------------------
-- 游戏服操作
REG(0xb000, "mail.op_new_mail")
REG(0xb001, "war.op_settlement")
REG(0xb002, "chat.op_broadcast")
REG(0xb003, "chat.op_private")
REG(0xb004, "quest.op_update")
REG(0xb005, "achieve.op_update")
REG(0xb006, "clock.op_zero")
REG(0xb007, "post.op_update_post")
REG(0xb008, "war.op_join_war")
REG(0xb009, "team.op_invite")
REG(0xb00a, "team.op_resp_invite")
REG(0xb00b, "team.op_req_join")
REG(0xb00c, "team.op_resp_join")
REG(0xb00e, "team.op_update_team")
REG(0xb00f, "team.op_join_team")
REG(0xb010, "team.op_leave_team")
REG(0xb011, "user.op_add_hero_exp")
REG(0xb012, "user.op_add_exp")


-- 国战服操作
-- war
REG(0xb100, "war.op_test")
REG(0xb101, "war.op_lock")
REG(0xb102, "war.op_start_fight")
REG(0xb103, "war.op_timeout")
REG(0xb104, "war.op_recover")

-- map
REG(0xb110, "map.op_move_troop")
REG(0xb111, "map.op_move_food")
REG(0xb112, "map.op_battle_lock")
REG(0xb113, "map.op_upgrade_building")
REG(0xb114, "map.op_battle_result")
REG(0xb115, "map.op_battle_settlement")
REG(0xb116, "map.op_assist")

return opcode
