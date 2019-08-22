local netplayer_data = netplayer_data or {
    C2GS = {},
    GS2C = {},
}

local C2GS = netplayer_data.C2GS
local GS2C = netplayer_data.GS2C

function C2GS.GetPlayerData(linkobj, message)
    local args = message.args
    local key = assert(args.key)
    local pid = assert(linkobj.pid)
    local player = gg.playermgr:getplayer(pid)
    if not player then
        local response = httpc.answer.response(httpc.answer.code.ROLE_NOEXIST)
        gg.actor.client:sendpackage(linkobj, "GS2C_GetPlayerDataResult", response, message.session)
        return
    end
    local val = player:get(key)
    local code = httpc.answer.code.OK
    gg.actor.client:sendpackage(linkobj, "GS2C_GetPlayerDataResult", {
        code = code,
        message = httpc.answer.message[code],
        key = key,
        val = val,
    }, message.session)
end

function C2GS.SetPlayerData(linkobj, message)
    local args = message.args
    local key = assert(args.key)
    local val = assert(args.val)
    local pid = assert(linkobj.pid)
    local player = gg.playermgr:getplayer(pid)
    if not player then
        local response = httpc.answer.response(httpc.answer.code.ROLE_NOEXIST)
        gg.actor.client:sendpackage(linkobj, "GS2C_SetPlayerDataResult", response, message.session)
        return
    end
    player:set(key, val)
    local code = httpc.answer.code.OK
    gg.actor.client:sendpackage(linkobj, "GS2C_SetPlayerDataResult", {
        code = code,
        message = httpc.answer.message[code],
        key = key,
    }, message.session)
end

function C2GS.PushPlayerData(linkobj, message)
    local args = message.args
    local key = assert(args.key)
    local val = assert(args.val)
    local pid = assert(linkobj.pid)
    local player = gg.playermgr:getplayer(pid)
    if not player then
        local response = httpc.answer.response(httpc.answer.code.ROLE_NOEXIST)
        gg.actor.client:sendpackage(linkobj, "GS2C_PushPlayerDataResult", response, message.session)
        return
    end
    
    local l_key = string.split(key, ".")
    if #l_key == 0 then
        local response = httpc.answer.response(httpc.answer.code.PARAM_ERR)
        gg.actor.client:sendpackage(linkobj, "GS2C_PushPlayerDataResult", response, message.session)
        return
    end
    
    for i, v in ipairs(l_key) do
        l_key[i] = tonumber(v) or v
    end
    
    local root_key = l_key[1]
    local t_old_val = {}
    local str_old_val = player:get(root_key)
    if str_old_val then
        t_old_val = cjson.decode(str_old_val)
    end
    
    local _, old_val = table.hasattr(t_old_val, l_key)
    print( gg.traceback.dumpvalue(t_old_val, -50) )
    print( gg.traceback.dumpvalue(old_val, -50) )
    if type(old_val) == "table" then
        if val.key then
            old_val[val.key] = val.val
        else
            table.insert(old_val, val.val)
        end
    elseif type(old_val) == "nil" then
        old_val = {}
        if val.key then
            old_val[val.key] = val.val
        else
            table.insert(old_val, val.val)
        end
    elseif type(old_val) == "string" then
        old_val = old_val .. val.val
    elseif type(old_val) == "number" and type(val.val) == "number" then
        old_val = old_val + val.val
    else
        local response = httpc.answer.response(httpc.answer.code.PARAM_ERR)
        gg.actor.client:sendpackage(linkobj, "GS2C_PushPlayerDataResult", response, message.session)
        return
    end
    
    table.setattr(t_old_val, l_key, old_val)
    
    local str_new_val = cjson.encode(t_old_val)
    player:set(root_key, str_new_val)
    local code = httpc.answer.code.OK
    gg.actor.client:sendpackage(linkobj, "GS2C_PushPlayerDataResult", {
        code = code,
        message = httpc.answer.message[code],
        key = key,
    }, message.session)
end

function __hotfix(module)
    gg.hotfix("app.game.client.client")
end

return netplayer_data
