---获取全局数据
--@author sundream
--@release 2019/8/29 16:30:00
--@usage
--api:      /api/account/getglobalvalue
--protocol: http/https
--method:   post
--params:
--  type=table encode=json
--  {
--      sign         [required] type=string help=签名
--      appid        [required] type=string help=appid
--      key          [required] type=string help=数据key(notice_config\weixin_shareurl)
--  }
--return:
--  type=table encode=json
--  {
--      code =      [required] type=number help=返回码
--      message =   [required] type=string help=返回码说明
--      data = {
--          key =   [required] type=string help=数据key
--          value = [required] type=string help=数据value(值类型是任意类型)
--      }
--  }
--  curl -v 'http://127.0.0.1:8885/api/account/getglobalvalue' -d '{"sign":"debug","appid":"appid","key":"notice_config"}'

local handler = {}

local safe_key = {
    notice_config = true,
    weixin_shareurl = true,
}

function handler.exec(linkobj, header, args)
    local request, err = table.check(args, {
        sign = {type = "string"},
        appid = {type = "string"},
        key = {type = "string"},
    })
    -- local response_header = httpc.allow_origin()
    if err then
        local response = httpc.answer.response(httpc.answer.code.PARAM_ERR)
        response.message = string.format("%s|%s", response.message, err)
        httpc.response_json(linkobj.linkid, 200, response, response_header)
        return
    end
    local key = request.key
    if not safe_key[key] then
        local response = httpc.answer.response(httpc.answer.code.PARAM_ERR)
        response.message = string.format("%s|%s", response.message, key)
        httpc.response_json(linkobj.linkid, 200, response, response_header)
        return
    end
    
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
    local value = skynet.getenv(key)
    local data = {
        key = key,
        value = value,
    }
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
