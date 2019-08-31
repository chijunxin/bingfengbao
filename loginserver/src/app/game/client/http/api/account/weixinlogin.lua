---微信登录
--@author sundream
--@release 2019/8/29 16:30:00
--@usage
--api:      /api/account/weixinlogin
--protocol: http/https
--method:   post
--params:
--  type=table encode=json
--  {
--      sign         [required] type=string help=签名
--      appid        [required] type=string help=appid
--      account      [required] type=string help=账号
--      access_token [requried] type=string help=微信验证用的token
--  }
--return:
--  type=table encode=json
--  {
--      code =      [required] type=number help=返回码
--      message =   [required] type=number help=返回码说明
--  }
--example:https://api.weixin.qq.com/sns/auth?access_token=ACCESS_TOKEN&openid=OPENID
--  curl -v 'http://127.0.0.1:8885/api/account/weixinlogin' -d '{"sign":"debug","appid":"appid","account":"openid","access_token":"1"}'

local handler = {}

function handler.exec(linkobj, header, args)
    local request, err = table.check(args, {
        sign = {type = "string"},
        appid = {type = "string"},
        account = {type = "string"},
        access_token = {type = "string"},
    })
    local response_header = httpc.allow_origin()
    if err then
        local response = httpc.answer.response(httpc.answer.code.PARAM_ERR)
        response.message = string.format("%s|%s", response.message, err)
        httpc.response_json(linkobj.linkid, 200, response, response_header)
        return
    end
    local appid = request.appid
    local account = request.account
    local access_token = request.access_token

    local app = util.get_app(appid)
    if not app then
        httpc.response_json(linkobj.linkid, 200, httpc.answer.response(httpc.answer.code.APPID_NOEXIST), response_header)
        return
    end
    local appkey = app.appkey
    if not httpc.check_signature(args.sign, args, appkey) then
        httpc.response_json(linkobj.linkid, 200, httpc.answer.response(httpc.answer.code.SIGN_ERR), response_header)
        return
    end
    -- 验证access_token
    local weixinURL = string.format("http://api.weixin.qq.com/sns/auth?access_token=%s&openid=%s", access_token, account)
    local respheader = {}
    httpc.dns()
    httpc.timeout = 300
    local status, body = httpc.get(weixinURL, "/", respheader)
    local weixinargs = cjson.decode(body)
    if weixinargs.errcode == nil or weixinargs.errcode ~= 0 then
        httpc.response_json(linkobj.linkid, 200, httpc.answer.response(httpc.answer.code.TOKEN_UNAUTH), response_header)
        return
    end
    
    local accountobj = accountmgr.getaccount(account)
    if not accountobj then
        -- 没有找到账号，自动创建账号
        local code = accountmgr.addaccount({
            account = account,
            passwd = "",
            sdk = "weixin",
            platform = "weixin",
        })
        if code ~= httpc.answer.code.OK then
            httpc.response_json(linkobj.linkid, 200, httpc.answer.response(code), response_header)
            return
        end
    end
    local token = access_token
    local data = {
        token = token,
        account = account,
    }
    accountmgr.addtoken(token, data)
    local response = httpc.answer.response(httpc.answer.code.OK)
    response.data = data
    httpc.response_json(linkobj.linkid, 200, response, response_header)
    return
end

function handler.POST(linkobj, header, query, body)
    local args = cjson.decode(body)
    handler.exec(linkobj, header, args)
end

function __hotfix(module)
    gg.hotfix("app.game.client.client")
end

return handler
